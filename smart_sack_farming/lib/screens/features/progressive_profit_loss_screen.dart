import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expense_model.dart';
import '../../theme/app_theme.dart';

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
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Pulses',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          
          projects.add(FarmingProject(
            id: projectData['id'],
            cropType: projectData['crop_type'],
            area: (projectData['area_hectares'] as num?)?.toDouble() ?? 0.0,
            plantingDate: DateTime.parse(projectData['planting_date']),
            harvestDate: DateTime.parse(projectData['harvest_date'] ?? projectData['planting_date']),
            revenue: (projectData['revenue'] as num?)?.toDouble() ?? 0.0,
            createdDate: DateTime.parse(projectData['created_at']),
            status: projectData['status'] ?? 'active',
            expenses: expenses.map((e) => Expense(
              id: e['id'],
              category: e['category'],
              description: e['description'] ?? '',
              amount: (e['amount'] as num).toDouble(),
              date: DateTime.parse(e['expense_date'] ?? e['created_at']),
              phase: e['phase'],
            )).toList(),
          ));
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
      setState(() => _isLoading = false);
      _initializeSampleProjects();
    }
  }

  void _initializeSampleProjects() {
    // Sample active project
    _activeProject = FarmingProject(
      id: '1',
      cropType: 'Rice',
      area: 5.0,
      plantingDate: DateTime.now().subtract(const Duration(days: 30)),
      harvestDate: DateTime.now().add(const Duration(days: 90)),
      revenue: 75000,
      expenses: [
        Expense(
          id: '1',
          category: 'Seeds',
          description: 'High-quality rice seeds 50kg',
          amount: 5000,
          date: DateTime.now().subtract(const Duration(days: 30)),
          phase: 'planting',
        ),
        Expense(
          id: '2',
          category: 'Fertilizer',
          description: 'NPK Fertilizer 100kg',
          amount: 8000,
          date: DateTime.now().subtract(const Duration(days: 25)),
          phase: 'planting',
        ),
        Expense(
          id: '3',
          category: 'Labor',
          description: 'Field preparation labor',
          amount: 6000,
          date: DateTime.now().subtract(const Duration(days: 28)),
          phase: 'planting',
        ),
      ],
      createdDate: DateTime.now().subtract(const Duration(days: 30)),
      status: 'active',
    );

    _allProjects = [
      _activeProject!,
      FarmingProject(
        id: '2',
        cropType: 'Wheat',
        area: 3.5,
        plantingDate: DateTime.now().subtract(const Duration(days: 180)),
        harvestDate: DateTime.now().subtract(const Duration(days: 60)),
        revenue: 52500,
        expenses: [
          Expense(
            id: '1',
            category: 'Seeds',
            description: 'Wheat seeds',
            amount: 4500,
            date: DateTime.now().subtract(const Duration(days: 180)),
            phase: 'planting',
          ),
          Expense(
            id: '2',
            category: 'Fertilizer',
            description: 'Urea fertilizer',
            amount: 7000,
            date: DateTime.now().subtract(const Duration(days: 170)),
            phase: 'planting',
          ),
          Expense(
            id: '3',
            category: 'Pesticides',
            description: 'Pest control spray',
            amount: 3500,
            date: DateTime.now().subtract(const Duration(days: 120)),
            phase: 'harvest',
          ),
        ],
        createdDate: DateTime.now().subtract(const Duration(days: 180)),
        status: 'completed',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addExpenseToActiveProject(Expense expense) {
    if (_activeProject == null) return;
    
    if (_userId != null) {
      // Save to Supabase
      Supabase.instance.client
          .from('expenses')
          .insert({
            'project_id': _activeProject!.id,
            'farmer_id': _userId,
            'category': expense.category,
            'description': expense.description,
            'amount': expense.amount,
            'expense_date': expense.date.toIso8601String().split('T').first,
            'phase': expense.phase,
          })
          .then((_) {
            // Reload projects to show new expense
            _loadProjectsFromSupabase();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Expense saved to database'),
                duration: Duration(seconds: 2),
              ),
            );
          })
          .catchError((e) {
            print('Error saving expense to Supabase: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error saving: ${e.toString()}'),
                duration: const Duration(seconds: 2),
              ),
            );
          });
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
    final formKey = GlobalKey<FormState>();
    String? cropType = _cropTypes.first;
    double? area;
    double? revenue;
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
                  decoration: const InputDecoration(labelText: 'Area (acres)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => area = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Expected Revenue (₹)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) => revenue = double.parse(value ?? '0'),
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                
                if (_userId != null) {
                  // Save to Supabase
                  Supabase.instance.client
                      .from('farming_projects')
                      .insert({
                        'farmer_id': _userId,
                        'crop_type': cropType ?? 'Rice',
                        'area_hectares': area ?? 0,
                        'planting_date': plantingDate.toIso8601String().split('T').first,
                        'harvest_date': harvestDate.toIso8601String().split('T').first,
                        'revenue': revenue ?? 0,
                        'status': 'active',
                      })
                      .then((_) {
                        Navigator.pop(context);
                        _loadProjectsFromSupabase();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Project created and saved'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      })
                      .catchError((e) {
                        print('Error creating project: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: ${e.toString()}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
                      decoration: const InputDecoration(labelText: 'Amount (₹)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => amount = double.parse(value ?? '0'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedPhase == 'planting'
                                  ? AppTheme.primary
                                  : AppTheme.inputBackground,
                            ),
                            onPressed: () {
                              setState(() => selectedPhase = 'planting');
                            },
                            child: Text(
                              'Planting',
                              style: TextStyle(
                                color: selectedPhase == 'planting'
                                    ? Colors.white
                                    : AppTheme.textMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedPhase == 'harvest'
                                  ? AppTheme.primary
                                  : AppTheme.inputBackground,
                            ),
                            onPressed: () {
                              setState(() => selectedPhase = 'harvest');
                            },
                            child: Text(
                              'Harvest',
                              style: TextStyle(
                                color: selectedPhase == 'harvest'
                                    ? Colors.white
                                    : AppTheme.textMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          'Area: ${_activeProject!.area} acres',
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
    
    return Container(
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
                    '${project.area} acres',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '₹${project.totalExpenses.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '₹${project.revenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Profit',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '₹${profit.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: profit >= 0 ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
                '₹${expense.amount.toStringAsFixed(2)}',
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
              _summaryItem('Revenue', '₹${_activeProject!.revenue.toStringAsFixed(0)}', Colors.white),
              _summaryItem('Expenses', '₹${_activeProject!.totalExpenses.toStringAsFixed(0)}', Colors.red),
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
                const Text(
                  'Net Profit',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '₹${_activeProject!.profit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color:
                        _activeProject!.profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
}
