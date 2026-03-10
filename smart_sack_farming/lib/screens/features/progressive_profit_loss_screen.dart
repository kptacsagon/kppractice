import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expense_model.dart';
import '../../services/profit_analytics_service.dart';
import '../../theme/app_theme.dart';
import 'project_detail_screen.dart';

class ProgressiveProfitLossCalculatorScreen extends StatefulWidget {
  const ProgressiveProfitLossCalculatorScreen({super.key});

  @override
  State<ProgressiveProfitLossCalculatorScreen> createState() =>
      _ProgressiveProfitLossCalculatorScreenState();
}

class _ProgressiveProfitLossCalculatorScreenState
    extends State<ProgressiveProfitLossCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _analytics = ProfitAnalyticsService();
  
  // Active project
  FarmingProject? _activeProject;
  List<FarmingProject> _allProjects = [];
  String? _userId;
  bool _isLoading = true;

  final List<String> _expenseCategories = [
    'Seeds',
    'Fertilizer',
    'Pesticides',
    'Labor',
    'Water',
    'Equipment Rental',
    'Transportation',
    'Storage',
    'Packaging',
    'Other',
  ];

  final List<String> _cropTypes = [
    'Rice (Palay)',
    'Corn (Mais)',
    'Coconut (Niyog)',
    'Sugarcane (Tubo)',
    'Banana (Saging)',
    'Vegetables (Gulay)',
    'Root Crops (Kamote/Gabi)',
    'Mango',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjectsFromSupabase();
  }

  Future<void> _loadProjectsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        
        // Load projects from Supabase
        final response = await Supabase.instance.client
            .from('farming_projects')
            .select()
            .eq('farmer_id', _userId!)
            .order('created_at', ascending: false);
        
        List<FarmingProject> projects = [];
        for (var projectData in response) {
          // Load expenses for this project
          final expenses = await Supabase.instance.client
              .from('expenses')
              .select()
              .eq('project_id', projectData['id'])
              .order('expense_date', ascending: false);
          
          final List<Expense> expenseList = [];
          for (var e in expenses) {
            expenseList.add(Expense(
              id: e['id']?.toString() ?? '',
              category: e['category'] ?? '',
              description: e['description'] ?? '',
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              date: DateTime.tryParse(e['expense_date'] ?? e['created_at'] ?? '') ?? DateTime.now(),
              phase: e['phase'] ?? 'planting',
            ));
          }
          
          var proj = FarmingProject(
            id: projectData['id']?.toString() ?? '',
            cropType: projectData['crop_type'] ?? 'Unknown',
            area: (projectData['area_hectares'] as num?)?.toDouble() ?? 0.0,
            plantingDate: DateTime.tryParse(projectData['planting_date'] ?? '') ?? DateTime.now(),
            harvestDate: DateTime.tryParse(projectData['harvest_date'] ?? projectData['planting_date'] ?? '') ?? DateTime.now(),
            revenue: (projectData['revenue'] as num?)?.toDouble() ?? 0.0,
            createdDate: DateTime.tryParse(projectData['created_at'] ?? '') ?? DateTime.now(),
            status: projectData['status'] ?? 'active',
            expenses: expenseList,
            expectedYieldKg: (projectData['expected_yield_kg'] as num?)?.toDouble() ?? 0.0,
            actualYieldKg: (projectData['actual_yield_kg'] as num?)?.toDouble() ?? 0.0,
            marketPricePerKg: (projectData['market_price_per_kg'] as num?)?.toDouble() ?? 0.0,
            expectedRevenue: (projectData['expected_revenue'] as num?)?.toDouble() ?? 0.0,
            actualSalePricePerKg: (projectData['actual_sale_price_per_kg'] as num?)?.toDouble() ?? 0.0,
          );
          proj = await _analytics.enrichWithMarketPrice(proj);
          projects.add(proj);
        }
        
        setState(() {
          _allProjects = projects;
          _activeProject = projects.isNotEmpty ? projects.first : null;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _initializeSampleProjects();
      }
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Only use sample data if we have nothing yet (first load)
        if (_allProjects.isEmpty) {
          _initializeSampleProjects();
        }
      }
    }
  }

  void _initializeSampleProjects() {
    // Sample active project — realistic Philippine rice farming (5 ha)
    // Total cost ~₱52K/ha × 5ha = ₱260K; Revenue ~₱350K
    _activeProject = FarmingProject(
      id: '1',
      cropType: 'Rice (Palay)',
      area: 5.0,
      plantingDate: DateTime.now().subtract(const Duration(days: 30)),
      harvestDate: DateTime.now().add(const Duration(days: 90)),
      revenue: 350000,
      expenses: [
        Expense(
          id: '1',
          category: 'Seeds',
          description: 'Certified RC222 seeds 250kg @ ₱120/kg',
          amount: 30000,
          date: DateTime.now().subtract(const Duration(days: 30)),
          phase: 'planting',
        ),
        Expense(
          id: '2',
          category: 'Fertilizer',
          description: 'Urea 20 bags + Complete 10 bags',
          amount: 70000,
          date: DateTime.now().subtract(const Duration(days: 25)),
          phase: 'planting',
        ),
        Expense(
          id: '3',
          category: 'Labor',
          description: 'Land preparation & transplanting (5 ha)',
          amount: 90000,
          date: DateTime.now().subtract(const Duration(days: 28)),
          phase: 'planting',
        ),
        Expense(
          id: '4',
          category: 'Equipment Rental',
          description: 'Tractor & rotavator rental',
          amount: 20000,
          date: DateTime.now().subtract(const Duration(days: 29)),
          phase: 'planting',
        ),
        Expense(
          id: '5',
          category: 'Water/Irrigation',
          description: 'Irrigation fees (wet season)',
          amount: 25000,
          date: DateTime.now().subtract(const Duration(days: 20)),
          phase: 'growing',
        ),
      ],
      createdDate: DateTime.now().subtract(const Duration(days: 30)),
      status: 'active',
      expectedYieldKg: 21000,    // 4.2 MT/ha × 5 ha
      marketPricePerKg: 21,      // ₱21/kg palay farmgate
      expectedRevenue: 441000,
    );

    _allProjects = [
      _activeProject!,
      // Completed corn project — realistic (3.5 ha)
      // Cost ~₱38K/ha × 3.5 = ₱133K; Revenue ~₱185K
      FarmingProject(
        id: '2',
        cropType: 'Corn (Mais)',
        area: 3.5,
        plantingDate: DateTime.now().subtract(const Duration(days: 180)),
        harvestDate: DateTime.now().subtract(const Duration(days: 60)),
        revenue: 185000,
        expenses: [
          Expense(
            id: '1',
            category: 'Seeds',
            description: 'Hybrid corn seeds 70kg',
            amount: 17500,
            date: DateTime.now().subtract(const Duration(days: 180)),
            phase: 'planting',
          ),
          Expense(
            id: '2',
            category: 'Fertilizer',
            description: 'Urea 14 bags + Complete 7 bags',
            amount: 35000,
            date: DateTime.now().subtract(const Duration(days: 170)),
            phase: 'growing',
          ),
          Expense(
            id: '3',
            category: 'Pesticides',
            description: 'Fall armyworm control spray × 3',
            amount: 14000,
            date: DateTime.now().subtract(const Duration(days: 120)),
            phase: 'growing',
          ),
          Expense(
            id: '4',
            category: 'Labor',
            description: 'Planting, weeding & harvest labor',
            amount: 42000,
            date: DateTime.now().subtract(const Duration(days: 90)),
            phase: 'harvest',
          ),
          Expense(
            id: '5',
            category: 'Equipment Rental',
            description: 'Corn sheller & hauling',
            amount: 14000,
            date: DateTime.now().subtract(const Duration(days: 65)),
            phase: 'post-harvest',
          ),
        ],
        createdDate: DateTime.now().subtract(const Duration(days: 180)),
        status: 'completed',
        expectedYieldKg: 16800,  // 4.8 MT/ha × 3.5 ha
        actualYieldKg: 15400,    // Slightly below expected
        marketPricePerKg: 12,    // ₱12/kg yellow corn
        expectedRevenue: 201600,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addExpenseToActiveProject(Expense expense) async {
    if (_activeProject == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (_userId != null) {
      try {
        await Supabase.instance.client
            .from('expenses')
            .insert({
              'project_id': _activeProject!.id,
              'farmer_id': _userId,
              'category': expense.category,
              'description': expense.description,
              'amount': expense.amount,
              'expense_date': expense.date.toIso8601String().split('T').first,
              'phase': expense.phase,
            });
        // Reload projects to show new expense
        await _loadProjectsFromSupabase();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Expense saved to database'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error saving expense to Supabase: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error saving: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Fallback for no user
      setState(() {
        _activeProject = _activeProject!.copyWith(
          expenses: [..._activeProject!.expenses, expense],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Expense added locally (not logged in)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startNewProject() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    String? cropType = _cropTypes.first;
    double? area;
    double? revenue;
    double? expectedYield;
    DateTime plantingDate = DateTime.now();
    DateTime harvestDate = DateTime.now().add(const Duration(days: 120));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Farming Project'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: cropType,
                  decoration: const InputDecoration(labelText: 'Crop Type'),
                  items: _cropTypes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => cropType = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Area (hectares)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => area = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Expected Revenue (\u20B1)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) => revenue = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Expected Yield (kg)',
                    hintText: 'e.g., 8000',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) => expectedYield = double.tryParse(value ?? '0') ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                
                if (_userId != null) {
                  try {
                    // Look up market price for this crop
                    final mktPrice = await _analytics.getMarketPrice(cropType ?? 'Rice');
                    final expYield = expectedYield ?? 0.0;
                    final expRev = mktPrice > 0 && expYield > 0
                        ? expYield * mktPrice
                        : (revenue ?? 0.0);

                    // Save to Supabase
                    await Supabase.instance.client
                        .from('farming_projects')
                        .insert({
                          'farmer_id': _userId,
                          'crop_type': cropType ?? 'Rice',
                          'area_hectares': area ?? 0,
                          'planting_date': plantingDate.toIso8601String().split('T').first,
                          'harvest_date': harvestDate.toIso8601String().split('T').first,
                          'revenue': revenue ?? 0,
                          'status': 'active',
                          'expected_yield_kg': expYield,
                          'market_price_per_kg': mktPrice,
                          'expected_revenue': expRev,
                        });
                    
                    // Close dialog first
                    if (context.mounted) Navigator.pop(context);
                    
                    // Reload projects from DB
                    await _loadProjectsFromSupabase();
                    
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ Project created and saved'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    print('Error creating project: $e');
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: ${e.toString()}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  // Fallback: local only
                  final newProject = FarmingProject(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cropType: cropType ?? 'Rice',
                    area: area ?? 0,
                    plantingDate: plantingDate,
                    harvestDate: harvestDate,
                    revenue: revenue ?? 0,
                    expenses: [],
                    createdDate: DateTime.now(),
                    status: 'active',
                  );
                  setState(() {
                    _activeProject = newProject;
                    _allProjects.insert(0, newProject);
                  });
                  if (context.mounted) Navigator.pop(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Project created locally (not logged in)'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddExpense() {
    if (_activeProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a project first')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String selectedCategory = _expenseCategories.first;
    String selectedPhase = 'planting';
    String? description;
    double? amount;
    DateTime selectedDate = DateTime.now();

    final cropPhases = {
      'planting': 'Land Preparation',
      'sowing': 'Planting / Sowing',
      'growing': 'Crop Maintenance',
      'harvest': 'Harvesting',
      'post-harvest': 'Post-Harvest',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Expense',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _expenseCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) =>
                          selectedCategory = value ?? _expenseCategories.first,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Urea fertilizer 50kg',
                      ),
                      onSaved: (value) => description = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Amount (₱)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => amount = double.parse(value ?? '0'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPhase,
                      decoration: const InputDecoration(labelText: 'Crop Stage'),
                      items: cropPhases.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ).toList(),
                      onChanged: (value) => setSheetState(() => selectedPhase = value ?? 'planting'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            final expense = Expense(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              category: selectedCategory,
                              description: description ?? selectedCategory,
                              amount: amount ?? 0,
                              date: selectedDate,
                              phase: selectedPhase,
                            );
                            _addExpenseToActiveProject(expense);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add Expense'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'P&L Calculator',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Active Project'),
            Tab(text: 'All Projects'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickAddExpense,
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primary,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveProjectTab(),
          _buildAllProjectsTab(),
          _buildComparisonTab(),
        ],
      ),
    );
  }

  Widget _buildActiveProjectTab() {
    if (_activeProject == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.agriculture_rounded, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            const Text(
              'No Active Project',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new farming project to begin tracking expenses',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startNewProject,
                icon: const Icon(Icons.add),
                label: const Text('Create New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeProject!.cropType,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area: ${_activeProject!.area} ha',
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Days remaining: ${_activeProject!.harvestDate.difference(DateTime.now()).inDays}',
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Financial Summary
          _buildSummaryCard(),
          const SizedBox(height: 20),
          // Expenses list
          Text(
            'Recent Expenses (${_activeProject!.expenses.length})',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_activeProject!.expenses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 48, color: AppTheme.textLight),
                    const SizedBox(height: 12),
                    const Text(
                      'No expenses yet',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeProject!.expenses.length,
              itemBuilder: (context, index) {
                final expense = _activeProject!.expenses[index];
                return _buildExpenseItem(expense, index);
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAllProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNewProject,
              icon: const Icon(Icons.add),
              label: const Text('Create New Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Projects (${_allProjects.length})',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allProjects.length,
            itemBuilder: (context, index) {
              final project = _allProjects[index];
              return _buildProjectCard(project);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(FarmingProject project) {
    final isCompleted = project.status == 'completed';
    final profit = project.profit;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        ).then((_) => _loadProjectsFromSupabase());
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.cropType,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.area} ha',
                    style: const TextStyle(
                      color: AppTheme.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.blue.withAlpha(20) : Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : 'ACTIVE',
                  style: TextStyle(
                    color: isCompleted ? Colors.blue : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _projMetric(project.expensesLabel, '\u20B1${project.totalExpenses.toStringAsFixed(0)}', AppTheme.textDark),
              _projMetric(project.revenueLabel, '\u20B1${project.actualRevenue.toStringAsFixed(0)}', Colors.green),
              _projMetric(project.profitLabel, '\u20B1${profit.toStringAsFixed(0)}',
                  profit >= 0 ? Colors.green : Colors.red),
              _projMetric('ROI', project.roiLabel,
                  project.roi.isNaN || project.roi >= 0 ? Colors.green : Colors.red),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _projMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.description,
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: expense.phase == 'planting'
                            ? Colors.green.withAlpha(20)
                            : Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        expense.phase,
                        style: TextStyle(
                          color: expense.phase == 'planting'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeProject = _activeProject!.copyWith(
                      expenses: _activeProject!.expenses
                          .where((e) => e.id != expense.id)
                          .toList(),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final p = _activeProject!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(p.revenueLabel, '\u20B1${p.actualRevenue.toStringAsFixed(0)}', Colors.white),
              _summaryItem(p.expensesLabel, '\u20B1${p.totalExpenses.toStringAsFixed(0)}', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.profitLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(
                  '\u20B1${p.profit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: p.profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ROI, Cost/Ha, Break-even row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('ROI', p.roiLabel,
                  p.roi.isNaN || p.roi >= 0 ? Colors.greenAccent : Colors.redAccent),
              _summaryItem('Cost/Ha', '\u20B1${_fmtNum(p.costPerHectare)}', Colors.white),
              _summaryItem('Break-even', '${_fmtNum(p.breakEvenYieldKg)} kg', Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MULTI-PROJECT COMPARISON TAB
  // ══════════════════════════════════════════════════════════════

  Widget _buildComparisonTab() {
    if (_allProjects.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compare_arrows_rounded, size: 64, color: AppTheme.textLight),
              const SizedBox(height: 16),
              const Text('Need at least 2 projects to compare',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startNewProject,
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by ROI descending (treat NaN as -infinity for sorting)
    final sorted = List<FarmingProject>.from(_allProjects)
      ..sort((a, b) {
        final aRoi = a.roi.isNaN ? double.negativeInfinity : a.roi;
        final bRoi = b.roi.isNaN ? double.negativeInfinity : b.roi;
        return bRoi.compareTo(aRoi);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Project Comparison',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${_allProjects.length} projects ranked by ROI',
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Comparison table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Crop', style: TextStyle(
                  color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('Profit', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('ROI', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('Cost/Ha', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('Risk', textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ),

          // Rows
          ...sorted.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isTop = i == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isTop ? Colors.green.withAlpha(8) : AppTheme.surface,
                border: Border(
                  left: BorderSide(color: AppTheme.border),
                  right: BorderSide(color: AppTheme.border),
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(children: [
                Expanded(flex: 3, child: Row(children: [
                  if (isTop) const Icon(Icons.emoji_events, color: Colors.amber, size: 16)
                  else const SizedBox(width: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.cropType, style: const TextStyle(
                          color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${p.area} ha', style: const TextStyle(
                          color: AppTheme.textLight, fontSize: 10)),
                    ]),
                  ),
                ])),
                Expanded(flex: 2, child: Text(
                  '\u20B1${_fmtNum(p.profit)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: p.profit >= 0 ? Colors.green : Colors.red,
                    fontSize: 12, fontWeight: FontWeight.w600),
                )),
                Expanded(flex: 2, child: Text(
                  p.roiLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: p.roi.isNaN || p.roi >= 0 ? Colors.green : Colors.red,
                    fontSize: 12, fontWeight: FontWeight.w600),
                )),
                Expanded(flex: 2, child: Text(
                  '\u20B1${_fmtNum(p.costPerHectare)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textDark, fontSize: 12),
                )),
                Expanded(flex: 2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.status == 'completed'
                          ? Colors.blue.withAlpha(15)
                          : Colors.green.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.status == 'completed' ? 'Done' : 'Active',
                      style: TextStyle(
                        color: p.status == 'completed' ? Colors.blue : Colors.green,
                        fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
              ]),
            );
          }),

          const SizedBox(height: 20),

          // Summary stats
          Row(children: [
            Expanded(child: _compStatCard(
              'Best ROI',
              sorted.first.cropType,
              sorted.first.roiLabel,
              Colors.green,
              Icons.trending_up_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _compStatCard(
              'Most Profitable',
              sorted.reduce((a, b) => a.profit > b.profit ? a : b).cropType,
              '\u20B1${_fmtNum(sorted.reduce((a, b) => a.profit > b.profit ? a : b).profit)}',
              Colors.green,
              Icons.attach_money_rounded,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _compStatCard(
              'Lowest Cost/Ha',
              sorted.where((p) => p.costPerHectare > 0).toList().isEmpty
                  ? '-'
                  : sorted.where((p) => p.costPerHectare > 0)
                      .reduce((a, b) => a.costPerHectare < b.costPerHectare ? a : b).cropType,
              sorted.where((p) => p.costPerHectare > 0).toList().isEmpty
                  ? '-'
                  : '\u20B1${_fmtNum(sorted.where((p) => p.costPerHectare > 0).reduce((a, b) => a.costPerHectare < b.costPerHectare ? a : b).costPerHectare)}',
              Colors.indigo,
              Icons.landscape_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _compStatCard(
              'Total Projects',
              '${_allProjects.where((p) => p.status == "active").length} active',
              '${_allProjects.length}',
              Colors.purple,
              Icons.folder_rounded,
            )),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _compStatCard(String label, String subtitle, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
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
            Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 10)),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMedium, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  String _fmtNum(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
