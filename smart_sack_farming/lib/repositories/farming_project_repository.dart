import '../models/expense_model.dart';
import '../services/supabase_service.dart';

class FarmingProjectRepository {
  final SupabaseService _supabaseService = SupabaseService();

  static const String _tableName = 'farming_projects';
  static const String _expensesTableName = 'expenses';

  /// Get all farming projects for the current user
  Future<List<FarmingProject>> getAllProjects(String userId) async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('farmer_id', userId)
          .order('created_at', ascending: false);

      final projects = List<FarmingProject>.from((response as List)
          .map((p) => FarmingProject.fromJson(p as Map<String, dynamic>)));

      // Fetch expenses for each project
      for (var project in projects) {
        final expenses =
            await getExpensesForProject(project.id, userId);
        project = project.copyWith(expenses: expenses);
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  /// Get a single farming project by ID
  Future<FarmingProject?> getProjectById(
      String projectId, String userId) async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('id', projectId)
          .eq('farmer_id', userId)
          .single();

      final project =
          FarmingProject.fromJson(response as Map<String, dynamic>);

      // Fetch expenses for this project
      final expenses = await getExpensesForProject(projectId, userId);
      return project.copyWith(expenses: expenses);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  /// Create a new farming project
  Future<FarmingProject> createProject(
    FarmingProject project,
    String userId,
  ) async {
    try {
      final data = {
        'farmer_id': userId,
        'crop_type': project.cropType,
        'area_hectares': project.area,
        'planting_date': project.plantingDate.toIso8601String(),
        'harvest_date': project.harvestDate.toIso8601String(),
        'revenue': project.revenue,
        'status': project.status,
      };

      final response = await _supabaseService.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return FarmingProject.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Update a farming project
  Future<void> updateProject(
    FarmingProject project,
    String userId,
  ) async {
    try {
      final data = {
        'crop_type': project.cropType,
        'area_hectares': project.area,
        'planting_date': project.plantingDate.toIso8601String(),
        'harvest_date': project.harvestDate.toIso8601String(),
        'revenue': project.revenue,
        'status': project.status,
      };

      await _supabaseService.client
          .from(_tableName)
          .update(data)
          .eq('id', project.id)
          .eq('farmer_id', userId);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Delete a farming project and its expenses
  Future<void> deleteProject(String projectId, String userId) async {
    try {
      // Delete expenses first
      await _supabaseService.client
          .from(_expensesTableName)
          .delete()
          .eq('project_id', projectId);

      // Delete project
      await _supabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', projectId)
          .eq('farmer_id', userId);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Get all expenses for a project
  Future<List<Expense>> getExpensesForProject(
    String projectId,
    String userId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from(_expensesTableName)
          .select()
          .eq('project_id', projectId)
          .eq('farmer_id', userId)
          .order('expense_date', ascending: false);

      return List<Expense>.from((response as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  /// Add an expense to a project
  Future<Expense> addExpense(
    Expense expense,
    String projectId,
    String userId,
  ) async {
    try {
      final data = {
        'project_id': projectId,
        'farmer_id': userId,
        'category': expense.category,
        'description': expense.description,
        'amount': expense.amount,
        'expense_date': expense.date.toIso8601String(),
        'phase': expense.phase,
      };

      final response = await _supabaseService.client
          .from(_expensesTableName)
          .insert(data)
          .select()
          .single();

      return Expense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(
    String expenseId,
    String userId,
  ) async {
    try {
      await _supabaseService.client
          .from(_expensesTableName)
          .delete()
          .eq('id', expenseId)
          .eq('farmer_id', userId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Update an expense
  Future<void> updateExpense(
    Expense expense,
    String userId,
  ) async {
    try {
      final data = {
        'category': expense.category,
        'description': expense.description,
        'amount': expense.amount,
        'expense_date': expense.date.toIso8601String(),
        'phase': expense.phase,
      };

      await _supabaseService.client
          .from(_expensesTableName)
          .update(data)
          .eq('id', expense.id)
          .eq('farmer_id', userId);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }
}
