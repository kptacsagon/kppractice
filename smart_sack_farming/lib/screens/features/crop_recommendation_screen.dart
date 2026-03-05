import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recommendation_model.dart';
import '../../services/recommendation_engine.dart';
import '../../theme/app_theme.dart';

/// Predictive crop recommendation screen that proactively suggests
/// optimal planting strategies based on land suitability, seasonal
/// constraints, regional saturation, and market prices.
class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final _engine = RecommendationEngine();
  late TabController _tabController;
  List<CropRecommendation> _recommendations = [];
  bool _isLoading = false;
  double _fieldAreaHa = 1.0;
  DateTime _plantingDate = DateTime.now();
  final _areaController = TextEditingController(text: '1.0');
  String _filterRisk = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final recs = await _engine.generateRecommendations(
        farmerId: user.id,
        fieldAreaHa: _fieldAreaHa,
        plantingDate: _plantingDate,
      );
      setState(() => _recommendations = recs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CropRecommendation> get _filteredSingleCrop {
    var list = _recommendations.where((r) => !r.isIntercrop).toList();
    if (_filterRisk != 'all') {
      list = list.where((r) => r.riskLevel == _filterRisk).toList();
    }
    return list;
  }

  List<CropRecommendation> get _filteredIntercrop {
    var list = _recommendations.where((r) => r.isIntercrop).toList();
    if (_filterRisk != 'all') {
      list = list.where((r) => r.riskLevel == _filterRisk).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Crop Recommendations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Single Crop'),
            Tab(text: 'Intercropping'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInputPanel(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecommendationList(_filteredSingleCrop),
                      _buildRecommendationList(_filteredIntercrop),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farm Parameters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _areaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Field Area (hectares)',
                    prefixIcon: Icon(Icons.landscape_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _fieldAreaHa = double.tryParse(v) ?? 1.0;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _plantingDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _plantingDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Planting Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      isDense: true,
                    ),
                    child: Text(
                      '${_plantingDate.day}/${_plantingDate.month}/${_plantingDate.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateRecommendations,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Recommendations'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Risk Filter: ',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
          const SizedBox(width: 8),
          ..._buildFilterChips(),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    return ['all', 'low', 'medium', 'high'].map((risk) {
      final isSelected = _filterRisk == risk;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(
            risk == 'all' ? 'All' : '${risk[0].toUpperCase()}${risk.substring(1)}',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
          ),
          selected: isSelected,
          selectedColor: AppTheme.primary,
          onSelected: (_) => setState(() => _filterRisk = risk),
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();
  }

  Widget _buildRecommendationList(List<CropRecommendation> recs) {
    if (recs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text('No recommendations found',
                style: TextStyle(color: AppTheme.textMedium)),
            Text('Try adjusting your parameters',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (context, index) =>
          _buildRecommendationCard(recs[index], index + 1),
    );
  }

  Widget _buildRecommendationCard(CropRecommendation rec, int rank) {
    final isTop3 = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTop3
            ? Border.all(color: AppTheme.primary.withAlpha(60), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getRiskColor(rec.riskLevel).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRiskColor(rec.riskLevel),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  rec.isIntercrop
                      ? '${rec.recommendedCrop} + ${rec.companionCrops.join(", ")}'
                      : rec.recommendedCrop,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getSuitabilityColor(rec.suitabilityScore)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rec.suitabilityPercent,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getSuitabilityColor(rec.suitabilityScore),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(rec.riskEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '${rec.riskLevel.toUpperCase()} RISK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRiskColor(rec.riskLevel),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₱${_formatNumber(rec.estimatedProfit)} profit',
                style: TextStyle(
                  fontSize: 11,
                  color: rec.estimatedProfit >= 0
                      ? AppTheme.success
                      : AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),

                  // ── Score Breakdown (5-Factor Model) ──
                  const Text(
                    'Crop Score Breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildScoreBar('Profit', rec.profitScore, 0.35,
                      Icons.attach_money, AppTheme.success),
                  _buildScoreBar('Climate', rec.climateScore, 0.20,
                      Icons.wb_sunny_rounded, Colors.orange),
                  _buildScoreBar('Market Opp.', rec.marketRiskScore, 0.20,
                      Icons.store_rounded, Colors.blue),
                  _buildScoreBar('Soil Match', rec.soilScore, 0.15,
                      Icons.grass_rounded, AppTheme.primary),
                  _buildScoreBar('Diversification', rec.diversificationScore,
                      0.10, Icons.diversity_3_rounded, Colors.purple),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Weighted Total: ${rec.suitabilityScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getSuitabilityColor(rec.suitabilityScore),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),

                  // ── Predictive Risk Model (4-Factor) ──
                  const Text(
                    'Predictive Risk Analysis',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRiskBar('Weather', rec.weatherRisk, 0.30,
                      Icons.thunderstorm_rounded),
                  _buildRiskBar('Market', rec.marketRisk, 0.30,
                      Icons.trending_down_rounded),
                  _buildRiskBar('Crop Sensitivity', rec.cropSensitivity, 0.20,
                      Icons.bug_report_rounded),
                  _buildRiskBar('Financial', rec.financialRisk, 0.20,
                      Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRiskColor(rec.riskLevel).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Risk Probability',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRiskColor(rec.riskLevel),
                          ),
                        ),
                        Text(
                          '${(rec.totalRiskScore * 100).toStringAsFixed(1)}% (${rec.riskLevel.toUpperCase()})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getRiskColor(rec.riskLevel),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),

                  // ── Financial summary ──
                  _buildDetailRow(
                      'Estimated Revenue', '₱${_formatNumber(rec.estimatedRevenue)}'),
                  _buildDetailRow(
                      'Estimated Cost', '₱${_formatNumber(rec.estimatedCost)}'),
                  _buildDetailRow(
                      'Estimated Profit',
                      '₱${_formatNumber(rec.estimatedProfit)}',
                      color: rec.estimatedProfit >= 0
                          ? AppTheme.success
                          : AppTheme.error),
                  const SizedBox(height: 8),
                  // Technical details
                  _buildDetailRow('Water Availability Index',
                      '${rec.waterAvailability.toStringAsFixed(1)}%'),
                  _buildDetailRow('Saturation Level',
                      rec.saturationLevel.toUpperCase()),
                  _buildDetailRow('Regional Saturation',
                      '${rec.regionalSaturation.toStringAsFixed(1)}%'),
                  _buildDetailRow('Season', rec.season),
                  if (rec.expectedHarvest != null)
                    _buildDetailRow('Expected Harvest',
                        '${rec.expectedHarvest!.day}/${rec.expectedHarvest!.month}/${rec.expectedHarvest!.year}'),
                  if (rec.isIntercrop) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: rec.companionCrops
                          .map((c) => Chip(
                                label: Text(c,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor:
                                    AppTheme.primaryLight.withAlpha(30),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Reason text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.reason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal bar showing a score factor with its weight contribution.
  Widget _buildScoreBar(String label, double value, double weight,
      IconData icon, Color color) {
    final weighted = value * weight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withAlpha(180),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}% ×${weight.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal bar showing a risk factor with its weight contribution.
  Widget _buildRiskBar(String label, double value, double weight,
      IconData icon) {
    final riskColor = value >= 0.7
        ? AppTheme.error
        : value >= 0.4
            ? AppTheme.warning
            : AppTheme.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: riskColor),
          const SizedBox(width: 6),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: riskColor.withAlpha(180),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}% ×${weight.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 10,
                color: riskColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMedium)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'low':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'high':
        return AppTheme.error;
      default:
        return AppTheme.textMedium;
    }
  }

  Color _getSuitabilityColor(double score) {
    if (score >= 70) return AppTheme.success;
    if (score >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
