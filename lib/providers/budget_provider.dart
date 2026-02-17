import 'package:flutter/material.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBudgetLimit => _budgets.fold(0, (sum, b) => sum + b.limit);
  double get totalSpent => _budgets.fold(0, (sum, b) => sum + b.spent);
  double get remainingBudget => totalBudgetLimit - totalSpent;

  Future<void> fetchBudgets() async {
    _isLoading = true;
    _error = null;

    try {
      // Mock data for demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      final now = DateTime.now();
      _budgets = [
        Budget(
          id: '1',
          category: 'Food',
          limit: 500.00,
          spent: 145.99,
          period: 'monthly',
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          userId: 'user_123',
        ),
        Budget(
          id: '2',
          category: 'Transport',
          limit: 300.00,
          spent: 52.00,
          period: 'monthly',
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          userId: 'user_123',
        ),
        Budget(
          id: '3',
          category: 'Entertainment',
          limit: 200.00,
          spent: 180.00,
          period: 'monthly',
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          userId: 'user_123',
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBudget(String category, double limit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final now = DateTime.now();
      final newBudget = Budget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: category,
        limit: limit,
        spent: 0,
        period: 'monthly',
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        userId: 'user_123',
        createdAt: DateTime.now(),
      );
      
      _budgets.insert(0, newBudget);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _budgets.removeWhere((budget) => budget.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
