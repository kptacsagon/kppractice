import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expense_model.dart';
import '../../services/profit_analytics_service.dart';
import '../../theme/app_theme.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  FarmingProject? _project;
  RiskAssessment? _risk;
  bool _isLoading = true;
  String? _error;
  final _analytics = ProfitAnalyticsService();
  List<Map<String, dynamic>> _linkedCalamities = [];  // Calamities linked to this project

  final List<String> _expenseCategories = [
    'Seeds', 'Fertilizer', 'Pesticides', 'Labor', 'Water',
    'Equipment Rental', 'Transportation', 'Storage', 'Packaging', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    try {
      setState(() { _isLoading = true; _error = null; });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() { _error = 'Not logged in'; _isLoading = false; });
        return;
      }

      // Fetch project
      final projectData = await Supabase.instance.client
          .from('farming_projects')
          .select()
          .eq('id', widget.projectId)
          .eq('farmer_id', user.id)
          .single();

      // Fetch expenses for this project
      final expensesData = await Supabase.instance.client
          .from('expenses')
          .select()
          .eq('project_id', widget.projectId)
          .order('expense_date', ascending: false);

      final List<Expense> expenseList = [];
      for (var e in expensesData) {
        expenseList.add(Expense(
          id: e['id']?.toString() ?? '',
          category: e['category'] ?? '',
          description: e['description'] ?? '',
          amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(e['expense_date'] ?? e['created_at'] ?? '') ??
              DateTime.now(),
          phase: e['phase'] ?? 'planting',
        ));
      }

      var project = FarmingProject(
        id: projectData['id']?.toString() ?? '',
        cropType: projectData['crop_type'] ?? 'Unknown',
        area: (projectData['area_hectares'] as num?)?.toDouble() ?? 0.0,
        plantingDate:
            DateTime.tryParse(projectData['planting_date'] ?? '') ?? DateTime.now(),
        harvestDate: DateTime.tryParse(
                projectData['harvest_date'] ?? projectData['planting_date'] ?? '') ??
            DateTime.now(),
        revenue: (projectData['revenue'] as num?)?.toDouble() ?? 0.0,
        createdDate:
            DateTime.tryParse(projectData['created_at'] ?? '') ?? DateTime.now(),
        status: projectData['status'] ?? 'active',
        expenses: expenseList,
        expectedYieldKg: (projectData['expected_yield_kg'] as num?)?.toDouble() ?? 0.0,
        actualYieldKg: (projectData['actual_yield_kg'] as num?)?.toDouble() ?? 0.0,
        marketPricePerKg: (projectData['market_price_per_kg'] as num?)?.toDouble() ?? 0.0,
        expectedRevenue: (projectData['expected_revenue'] as num?)?.toDouble() ?? 0.0,
        actualSalePricePerKg: (projectData['actual_sale_price_per_kg'] as num?)?.toDouble() ?? 0.0,
      );

      // Enrich with market price if missing
      project = await _analytics.enrichWithMarketPrice(project);

      // Assess risk
      final risk = await _analytics.assessRisk(
        farmerId: user.id,
        cropType: project.cropType,
        areaHectares: project.area,
      );

      // Fetch linked calamities
      final calamities = await Supabase.instance.client
          .from('calamity_reports')
          .select()
          .eq('project_id', widget.projectId)
          .order('date_occurred', ascending: false);
      
      final linkedCalamities = List<Map<String, dynamic>>.from(calamities);

      setState(() {
        _project = project;
        _risk = risk;
        _linkedCalamities = linkedCalamities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading project details: $e');
      setState(() {
        _error = 'Failed to load project: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int get _daysRemaining {
    if (_project == null) return 0;
    if (_project!.status == 'completed') return 0;
    final diff = _project!.harvestDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  int get _totalDays {
    if (_project == null) return 1;
    final diff = _project!.harvestDate.difference(_project!.plantingDate).inDays;
    return diff > 0 ? diff : 1;
  }

  double get _progressPercent {
    if (_project == null || _project!.status == 'completed') return 1.0;
    final elapsed = DateTime.now().difference(_project!.plantingDate).inDays;
    return (elapsed / _totalDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _project?.cropType ?? 'Project Details',
          style: const TextStyle(
            color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_project != null && _project!.isActive) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
              tooltip: 'Complete Project',
              onPressed: _showCompleteProjectDialog,
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.textMedium),
              tooltip: 'Update Yield / Revenue',
              onPressed: _showUpdateYieldDialog,
            ),
          ] else if (_project != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.textMedium),
              tooltip: 'Update Yield / Revenue',
              onPressed: _showUpdateYieldDialog,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMedium),
            onPressed: _loadProjectDetails,
          ),
        ],
      ),
      floatingActionButton: (_project != null)
          ? FloatingActionButton.extended(
              onPressed: _showAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              backgroundColor: AppTheme.primary,
            )
          : null,
      body: _buildBody(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BODY
  // ════════════════════════════════════════════════════════════════

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading project...', style: TextStyle(color: AppTheme.textMedium)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.textMedium)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProjectDetails, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_project == null) {
      return const Center(
        child: Text('Project not found', style: TextStyle(color: AppTheme.textMedium)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectSummary(),
            const SizedBox(height: 16),
            _buildFinancialOverview(),
            const SizedBox(height: 16),
            _buildRiskIndicatorCard(),
            const SizedBox(height: 16),
            _buildCalamityImpactCard(),
            const SizedBox(height: 16),
            _buildForecastComparisonCard(),
            const SizedBox(height: 16),
            _buildSeasonalCashFlowCard(),
            const SizedBox(height: 16),
            _buildExpensesByCategory(),
            const SizedBox(height: 16),
            _buildExpensesByPhase(),
            const SizedBox(height: 16),
            _buildRecentExpenses(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  1. PROJECT SUMMARY CARD
  // ════════════════════════════════════════════════════════════════

  Widget _buildProjectSummary() {
    final p = _project!;
    final isActive = p.status == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.cropType,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${p.area} hectares',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                  ],
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? Colors.greenAccent.withAlpha(50) : Colors.blueAccent.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.greenAccent.withAlpha(120) : Colors.blueAccent.withAlpha(120),
                  ),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'COMPLETED',
                  style: TextStyle(
                    color: isActive ? Colors.greenAccent : Colors.lightBlueAccent,
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isActive ? '$_daysRemaining days remaining' : 'Harvest completed',
                style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(_progressPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progressPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive ? Colors.greenAccent : Colors.lightBlueAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _datePill(Icons.calendar_today, 'Planted', _formatDate(p.plantingDate)),
              _datePill(Icons.event_available, 'Harvest', _formatDate(p.harvestDate)),
              _datePill(Icons.timer_outlined, 'Duration', '$_totalDays days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePill(IconData icon, String label, String value) {
    return Column(children: [
      Icon(icon, color: Colors.white.withAlpha(180), size: 16),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  //  2. FINANCIAL OVERVIEW (Revenue, Expenses, Profit, ROI, etc.)
  // ════════════════════════════════════════════════════════════════

  Widget _buildFinancialOverview() {
    final p = _project!;
    final netProfit = p.profit;

    return _card(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Financial Overview',
      children: [
        // Row 1: Revenue, Expenses, Net Profit
        Row(children: [
          Expanded(child: _metricTile(p.revenueLabel, '\u20B1${_fmt(p.actualRevenue)}', Icons.trending_up, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile(p.expensesLabel, '\u20B1${_fmt(p.totalExpenses)}', Icons.trending_down, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile(p.profitLabel, '\u20B1${_fmt(netProfit)}',
              netProfit >= 0 ? Icons.check_circle : Icons.warning,
              netProfit >= 0 ? Colors.green : Colors.red)),
        ]),
        const SizedBox(height: 12),

        // Row 2: ROI, Cost/Ha, Break-even
        Row(children: [
          Expanded(child: _metricTile('ROI', p.roiLabel,
              Icons.show_chart_rounded,
              p.roi.isNaN || p.roi >= 0 ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile('Cost / Ha', '\u20B1${_fmt(p.costPerHectare)}',
              Icons.landscape_rounded, Colors.indigo)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile('Break-even', '${_fmt(p.breakEvenYieldKg)} kg',
              Icons.balance_rounded, Colors.deepPurple)),
        ]),
        const SizedBox(height: 12),

        // Profit margin bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: netProfit >= 0 ? Colors.green.withAlpha(15) : Colors.red.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(
              netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: netProfit >= 0 ? Colors.green : Colors.red, size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profit Margin: ${p.profitMargin.toStringAsFixed(1)}%  \u2022  '
                'Market Price: \u20B1${p.marketPricePerKg.toStringAsFixed(2)}/kg',
                style: TextStyle(
                  color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 13, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),

        // Risk-adjusted profit (if risk data is available)
        if (_risk != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.shield_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Risk-Adjusted Profit: \u20B1${_fmt(_risk!.riskAdjustedProfit(p.profit))}  '
                  '(${_risk!.overallRiskLabel} risk)',
                  style: TextStyle(color: Colors.amber.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  3. RISK INDICATOR CARD
  // ════════════════════════════════════════════════════════════════

  Widget _buildRiskIndicatorCard() {
    if (_risk == null) return const SizedBox.shrink();
    final r = _risk!;

    Color riskColor(double v) {
      if (v < 30) return Colors.green;
      if (v < 60) return Colors.orange;
      return Colors.red;
    }

    return _card(
      icon: Icons.warning_amber_rounded,
      title: 'Risk Assessment',
      titleColor: riskColor(r.overallRisk),
      children: [
        // Overall score
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: riskColor(r.overallRisk).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: riskColor(r.overallRisk).withAlpha(40)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: riskColor(r.overallRisk).withAlpha(30),
              ),
              child: Center(
                child: Text(
                  '${r.overallRisk.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: riskColor(r.overallRisk),
                    fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Overall Risk: ${r.overallRiskLabel}',
                    style: TextStyle(color: riskColor(r.overallRisk),
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Composite of saturation, market & calamity',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Individual risks
        _riskRow('Saturation Risk', r.saturationRisk, riskColor(r.saturationRisk),
            '${r.saturationLevel} moisture', Icons.water_drop_rounded),
        const SizedBox(height: 10),
        _riskRow('Market Risk', r.marketRisk, riskColor(r.marketRisk),
            'Trend: ${r.marketTrend}', Icons.store_rounded),
        const SizedBox(height: 10),
        _riskRow('Calamity Risk', r.calamityRisk, riskColor(r.calamityRisk),
            '${r.recentCalamities} events (6mo)', Icons.thunderstorm_rounded),
      ],
    );
  }

  Widget _riskRow(String label, double value, Color color, String sub, IconData icon) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${value.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppTheme.textLight, fontSize: 10)),
        ]),
      ),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  //  4. CALAMITY IMPACT CARD
  // ════════════════════════════════════════════════════════════════

  Widget _buildCalamityImpactCard() {
    if (_linkedCalamities.isEmpty) return const SizedBox.shrink();

    // Calculate total loss and group by severity
    double totalLoss = 0;
    final calamitiesByLevel = <String, List<Map<String, dynamic>>>{};
    
    for (final c in _linkedCalamities) {
      final severity = (c['severity'] as String?)?.toUpperCase() ?? 'LOW';
      final loss = (c['estimated_financial_loss'] as num?)?.toDouble() ?? 0.0;
      totalLoss += loss;
      
      calamitiesByLevel.putIfAbsent(severity, () => []);
      calamitiesByLevel[severity]!.add(c);
    }

    Color severityColor(String severity) {
      switch (severity.toUpperCase()) {
        case 'HIGH': return Colors.red;
        case 'MEDIUM': return Colors.orange;
        default: return Colors.amber;
      }
    }

    return _card(
      icon: Icons.cloud_queue_rounded,
      title: 'Calamity Impact',
      titleColor: Colors.red,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withAlpha(30)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withAlpha(25),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Financial Impact', 
                    style: TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('₱${totalLoss.toStringAsFixed(0)} estimated loss',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Calamities by severity
        ...['HIGH', 'MEDIUM', 'LOW'].expand((level) {
          final items = calamitiesByLevel[level] ?? [];
          if (items.isEmpty) return [];
          
          return [
            ...items.map((c) {
              final type = c['calamity_type'] as String? ?? 'Unknown';
              final cropStage = c['crop_stage'] as String? ?? 'Unknown Stage';
              final loss = (c['estimated_financial_loss'] as num?)?.toDouble() ?? 0.0;
              final dateOccurred = c['date_occurred'] as String?;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: severityColor(level).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      level == 'HIGH' ? Icons.error_rounded : 
                      level == 'MEDIUM' ? Icons.warning_rounded : 
                      Icons.info_rounded,
                      color: severityColor(level),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          child: Text(type,
                              style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor(level).withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(level,
                              style: TextStyle(color: severityColor(level), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${cropStage} • ${dateOccurred ?? ''}',
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                        Text('−₱${loss.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  ),
                ]),
              );
            }).toList(),
            if (items != calamitiesByLevel.values.last) const SizedBox(height: 8),
          ];
        }).toList(),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withAlpha(30)),
          ),
          child: Row(children: [
            Icon(Icons.lightbulb_outlined, color: Colors.blue.shade400, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Expected revenue automatically adjusted by ₱${totalLoss.toStringAsFixed(0)} due to calamity impact',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  5. FORECAST vs ACTUAL COMPARISON
  // ════════════════════════════════════════════════════════════════

  Widget _buildForecastComparisonCard() {
    final p = _project!;
    final comparisons = _analytics.buildForecastComparison(p);
    final hasData = p.expectedYieldKg > 0 || p.expectedRevenue > 0;

    return _card(
      icon: Icons.compare_arrows_rounded,
      title: 'Forecast vs Actual',
      children: [
        if (!hasData)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Column(children: [
              const Icon(Icons.info_outline, color: AppTheme.textLight, size: 32),
              const SizedBox(height: 8),
              const Text('Set expected yield to see forecast comparison',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showUpdateYieldDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update Yield Data'),
              ),
            ]),
          )
        else ...[
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Metric', style: TextStyle(
                  color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('Expected', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Actual', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Variance', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 4),
          ...comparisons.map((c) => _forecastRow(c)),
        ],
      ],
    );
  }

  Widget _forecastRow(ForecastComparison c) {
    final isGood = c.isPositive;
    final varColor = isGood ? Colors.green : Colors.red;
    final varSign = isGood ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border.withAlpha(80))),
      ),
      child: Row(children: [
        Expanded(flex: 3, child: Text(c.metric,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(flex: 2, child: Text(_fmt(c.expected), textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12))),
        Expanded(flex: 2, child: Text(_fmt(c.actual), textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(
          '$varSign${c.variancePercent.toStringAsFixed(1)}%',
          textAlign: TextAlign.right,
          style: TextStyle(color: varColor, fontSize: 12, fontWeight: FontWeight.w700),
        )),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  5. SEASONAL CASH FLOW
  // ════════════════════════════════════════════════════════════════

  Widget _buildSeasonalCashFlowCard() {
    final flow = _project!.monthlyCashFlow;
    if (flow.isEmpty) return const SizedBox.shrink();

    final maxAbs = flow.values.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    return _card(
      icon: Icons.timeline_rounded,
      title: 'Seasonal Cash Flow',
      children: [
        const Text('Monthly view: green = income, red = expense',
            style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
        const SizedBox(height: 12),
        ...flow.entries.map((entry) {
          final isPositive = entry.value >= 0;
          final ratio = maxAbs > 0 ? (entry.value.abs() / maxAbs) : 0.0;
          final color = isPositive ? Colors.green : Colors.red;
          final monthLabel = _monthName(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 60,
                child: Text(monthLabel,
                    style: const TextStyle(color: AppTheme.textMedium, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Stack(children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.border.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.05, 1.0),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withAlpha(isPositive ? 160 : 120),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '${isPositive ? "+" : ""}\u20B1${_fmt(entry.value)}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  6. EXPENSE BREAKDOWN BY CATEGORY
  // ════════════════════════════════════════════════════════════════

  Widget _buildExpensesByCategory() {
    final categories = _project!.expensesByCategory;
    if (categories.isEmpty) return const SizedBox.shrink();

    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _project!.totalExpenses;

    final categoryColors = {
      'Seeds': Colors.green, 'Fertilizer': Colors.lightGreen, 'Pesticides': Colors.orange,
      'Labor': Colors.blue, 'Water': Colors.cyan, 'Equipment Rental': Colors.indigo,
      'Transportation': Colors.purple, 'Storage': Colors.brown,
      'Packaging': Colors.pink, 'Other': Colors.grey,
    };

    return _card(
      icon: Icons.pie_chart_rounded,
      title: 'Expense Breakdown',
      children: [
        ...sortedEntries.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = categoryColors[entry.key] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Text(entry.key, style: const TextStyle(color: AppTheme.textDark, fontSize: 13)),
                ]),
                Text('\u20B1${_fmt(entry.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(color: AppTheme.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  7. EXPENSE BREAKDOWN BY PHASE
  // ════════════════════════════════════════════════════════════════

  Widget _buildExpensesByPhase() {
    final phases = _project!.expensesByPhase;
    if (phases.isEmpty) return const SizedBox.shrink();

    final total = _project!.totalExpenses;
    final phaseColors = {
      'planting': Colors.green,
      'growing': Colors.blue,
      'harvest': Colors.orange,
      'post-harvest': Colors.purple,
    };

    return _card(
      icon: Icons.layers_rounded,
      title: 'Cost per Growth Phase',
      children: [
        ...phases.entries.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = phaseColors[entry.key] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  entry.key == 'planting' ? Icons.grass :
                  entry.key == 'growing' ? Icons.nature :
                  entry.key == 'harvest' ? Icons.agriculture : Icons.inventory,
                  color: color, size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_capitalize(entry.key),
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('\u20B1${_fmt(entry.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 6,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  8. RECENT EXPENSES LIST
  // ════════════════════════════════════════════════════════════════

  Widget _buildRecentExpenses() {
    final expenses = _project!.expenses;

    return _card(
      icon: Icons.receipt_long_rounded,
      title: 'Recent Expenses',
      trailing: Text('${expenses.length} items',
          style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
      children: [
        if (expenses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const Column(children: [
              Icon(Icons.receipt_long, size: 40, color: AppTheme.textLight),
              SizedBox(height: 8),
              Text('No expenses recorded yet',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            ]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
            itemBuilder: (context, index) => _buildExpenseRow(expenses[index]),
          ),
      ],
    );
  }

  Widget _buildExpenseRow(Expense exp) {
    final phaseColor = exp.phase == 'planting' ? Colors.green : Colors.orange;
    final categoryIcons = {
      'Seeds': Icons.grass, 'Fertilizer': Icons.science, 'Pesticides': Icons.bug_report,
      'Labor': Icons.engineering, 'Water': Icons.water_drop, 'Equipment Rental': Icons.agriculture,
      'Transportation': Icons.local_shipping, 'Storage': Icons.warehouse,
      'Packaging': Icons.inventory_2, 'Other': Icons.more_horiz,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(categoryIcons[exp.category] ?? Icons.receipt,
              color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exp.category,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
            if (exp.description.isNotEmpty)
              Text(exp.description,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: phaseColor.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(exp.phase,
              style: TextStyle(color: phaseColor, fontSize: 9, fontWeight: FontWeight.w600)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\u20B1${_fmt(exp.amount)}',
              style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(_formatDate(exp.date),
              style: const TextStyle(color: AppTheme.textLight, fontSize: 10)),
        ]),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  UPDATE YIELD / REVENUE DIALOG
  // ════════════════════════════════════════════════════════════════

  void _showUpdateYieldDialog() {
    final p = _project!;
    final formKey = GlobalKey<FormState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    double expectedYield = p.expectedYieldKg;
    double actualYield = p.actualYieldKg;
    double manualRevenue = p.revenue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Yield & Revenue'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Market Price: \u20B1${p.marketPricePerKg.toStringAsFixed(2)}/kg\n'
                        'Revenue = Yield \u00D7 Market Price',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: expectedYield > 0 ? expectedYield.toStringAsFixed(0) : '',
                  decoration: const InputDecoration(
                    labelText: 'Expected Yield (kg)',
                    prefixIcon: Icon(Icons.agriculture),
                    hintText: 'e.g., 8000',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (v) => expectedYield = double.tryParse(v ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: actualYield > 0 ? actualYield.toStringAsFixed(0) : '',
                  decoration: const InputDecoration(
                    labelText: 'Actual Yield (kg)',
                    prefixIcon: Icon(Icons.scale),
                    hintText: 'Fill after harvest',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (v) => actualYield = double.tryParse(v ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: manualRevenue > 0 ? manualRevenue.toStringAsFixed(0) : '',
                  decoration: const InputDecoration(
                    labelText: 'Manual Revenue (\u20B1)',
                    prefixIcon: Icon(Icons.payments_rounded),
                    hintText: 'Override if needed',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (v) => manualRevenue = double.tryParse(v ?? '0') ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              formKey.currentState!.save();
              try {
                await Supabase.instance.client
                    .from('farming_projects')
                    .update({
                      'expected_yield_kg': expectedYield,
                      'actual_yield_kg': actualYield,
                      'revenue': manualRevenue,
                      'expected_revenue': expectedYield * p.marketPricePerKg,
                    })
                    .eq('id', widget.projectId);

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadProjectDetails();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('\u2705 Yield & revenue updated'), duration: Duration(seconds: 2)),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('\u274C Error: ${e.toString()}'), duration: const Duration(seconds: 3)),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMPLETE PROJECT DIALOG
  // ════════════════════════════════════════════════════════════════

  void _showCompleteProjectDialog() {
    final p = _project!;
    final formKey = GlobalKey<FormState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    double actualYield = p.actualYieldKg > 0 ? p.actualYieldKg : 0;
    double actualSalePrice = p.actualSalePricePerKg > 0
        ? p.actualSalePricePerKg
        : p.marketPricePerKg;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 8),
          const Text('Complete Project'),
        ]),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withAlpha(60)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter your actual harvest results to finalize this project. '
                        'This will lock the project as completed.',
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Project summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.cropType} • ${p.area} ha',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Expected Yield: ${p.expectedYieldKg.toStringAsFixed(0)} kg\n'
                        'Projected Price: \u20B1${p.marketPricePerKg.toStringAsFixed(2)}/kg\n'
                        'Total Expenses: \u20B1${p.totalExpenses.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  initialValue: actualYield > 0 ? actualYield.toStringAsFixed(0) : '',
                  decoration: const InputDecoration(
                    labelText: 'Actual Yield Sold (kg)',
                    prefixIcon: Icon(Icons.scale),
                    hintText: 'Total kg actually harvested & sold',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) {
                      return 'Enter a valid yield';
                    }
                    return null;
                  },
                  onSaved: (v) => actualYield = double.tryParse(v ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  initialValue: actualSalePrice > 0 ? actualSalePrice.toStringAsFixed(2) : '',
                  decoration: const InputDecoration(
                    labelText: 'Average Sale Price (\u20B1/kg)',
                    prefixIcon: Icon(Icons.payments_rounded),
                    hintText: 'Actual price you sold at',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                  onSaved: (v) => actualSalePrice = double.tryParse(v ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),

                // Preview calculated revenue
                Builder(builder: (context) {
                  final previewRevenue = actualYield * actualSalePrice;
                  final previewProfit = previewRevenue - p.totalExpenses;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: previewProfit >= 0
                          ? Colors.green.withAlpha(10)
                          : Colors.red.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Revenue:', style: TextStyle(fontSize: 12)),
                          Text('\u20B1${previewRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Profit:', style: TextStyle(fontSize: 12)),
                          Text(
                            '\u20B1${previewProfit.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: previewProfit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();

              final actualRevenue = actualYield * actualSalePrice;

              try {
                await Supabase.instance.client
                    .from('farming_projects')
                    .update({
                      'status': 'completed',
                      'actual_yield_kg': actualYield,
                      'actual_sale_price_per_kg': actualSalePrice,
                      'revenue': actualRevenue,
                    })
                    .eq('id', widget.projectId);

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadProjectDetails();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('\u2705 Project completed! Final P&L recorded.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('\u274C Error: ${e.toString()}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Complete Project'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ADD EXPENSE BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════

  void _showAddExpense() {
    final formKey = GlobalKey<FormState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String selectedCategory = _expenseCategories.first;
    String selectedPhase = 'planting';
    String? description;
    double? amount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                  const Text('Add Expense',
                      style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                    items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => selectedCategory = v ?? _expenseCategories.first,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description', hintText: 'e.g., Urea fertilizer 50kg',
                      prefixIcon: Icon(Icons.description),
                    ),
                    onSaved: (v) => description = v,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount (\u20B1)', prefixIcon: Icon(Icons.payments_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onSaved: (v) => amount = double.tryParse(v ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 14),

                  // Crop Stage selector (dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedPhase,
                    decoration: const InputDecoration(
                      labelText: 'Crop Stage',
                      prefixIcon: Icon(Icons.agriculture),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'planting', child: Text('Land Preparation')),
                      DropdownMenuItem(value: 'sowing', child: Text('Planting / Sowing')),
                      DropdownMenuItem(value: 'growing', child: Text('Crop Maintenance')),
                      DropdownMenuItem(value: 'harvest', child: Text('Harvesting')),
                      DropdownMenuItem(value: 'post-harvest', child: Text('Post-Harvest')),
                    ],
                    onChanged: (v) => setSheetState(() => selectedPhase = v ?? 'planting'),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        formKey.currentState!.save();

                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return;

                        try {
                          await Supabase.instance.client.from('expenses').insert({
                            'project_id': widget.projectId,
                            'farmer_id': user.id,
                            'category': selectedCategory,
                            'description': description ?? selectedCategory,
                            'amount': amount ?? 0,
                            'expense_date': DateTime.now().toIso8601String().split('T').first,
                            'phase': selectedPhase,
                          });

                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _loadProjectDetails();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('\u2705 Expense saved'), duration: Duration(seconds: 2)),
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('\u274C Error: ${e.toString()}'), duration: const Duration(seconds: 3)),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phaseButton(String value, String label, Color activeColor,
      String current, StateSetter setSheetState, ValueChanged<String> onSelect) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() => onSelect(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppTheme.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : AppTheme.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMedium,
                fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SHARED UI COMPONENTS
  // ════════════════════════════════════════════════════════════════

  Widget _card({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: titleColor ?? AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(
                color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          if (trailing != null) trailing,
        ]),
        const Divider(height: 24),
        ...children,
      ]),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmt(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _monthName(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${months[m - 1]} ${parts[0].substring(2)}';
  }
}
