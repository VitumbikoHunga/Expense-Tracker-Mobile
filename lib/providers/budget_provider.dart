import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

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
    notifyListeners();

    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      // try to load any budgets saved in shared prefs, otherwise fall back to default
      _budgets = await _loadMockBudgets();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get(AppConstants.budgetsEndpoint);
      if (response is List) {
        _budgets = response
            .map((e) => Budget.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['data'] is List) {
        _budgets = (response['data'] as List)
            .map((e) => Budget.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _budgets = [];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBudget(String category, double limit) async {
    if (AppConstants.useMockApi) {
      final created = Budget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: category,
        limit: limit,
        spent: 0,
        period: 'monthly',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        userId: '1',
      );
      _budgets.insert(0, created);
      await _saveMockBudgets();
      notifyListeners();
      return true;
    }

    try {
      final data = {
        'category': category,
        'limit': limit,
      };
      final response = await ApiService().post(
        AppConstants.createBudgetEndpoint,
        data: data,
      );
      final created = Budget.fromJson(response as Map<String, dynamic>);
      _budgets.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    if (AppConstants.useMockApi) {
      _budgets.removeWhere((budget) => budget.id == id);
      await _saveMockBudgets();
      notifyListeners();
      return true;
    }

    try {
      await ApiService().delete('${AppConstants.budgetsEndpoint}/$id');
      _budgets.removeWhere((budget) => budget.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Adjust the spent amount for a budget when receipts are added/removed.
  void addToBudget(String budgetId, double amount) {
    final idx = _budgets.indexWhere((b) => b.id == budgetId);
    if (idx != -1) {
      final b = _budgets[idx];
      _budgets[idx] = Budget(
        id: b.id,
        category: b.category,
        limit: b.limit,
        spent: b.spent + amount,
        period: b.period,
        startDate: b.startDate,
        endDate: b.endDate,
        userId: b.userId,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      );
      if (AppConstants.useMockApi) {
        _saveMockBudgets();
      }
      notifyListeners();
    }
  }

  void removeFromBudget(String budgetId, double amount) {
    final idx = _budgets.indexWhere((b) => b.id == budgetId);
    if (idx != -1) {
      final b = _budgets[idx];
      _budgets[idx] = Budget(
        id: b.id,
        category: b.category,
        limit: b.limit,
        spent: (b.spent - amount).clamp(0, double.infinity),
        period: b.period,
        startDate: b.startDate,
        endDate: b.endDate,
        userId: b.userId,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      );
      if (AppConstants.useMockApi) {
        _saveMockBudgets();
      }
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --- helpers for mock persistence ------------------------------------------------

  static const _mockKey = 'mock_budgets';

  Future<List<Budget>> _loadMockBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mockKey);
    if (jsonString == null) {
      return [
        Budget(
          id: 'b1',
          category: 'Food',
          limit: 500.0,
          spent: 120.0,
          period: 'monthly',
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          endDate: DateTime.now().add(const Duration(days: 15)),
          userId: '1',
        )
      ];
    }
    final List decoded = json.decode(jsonString) as List;
    return decoded
        .map((e) => Budget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveMockBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_budgets.map((b) => b.toJson()).toList());
    await prefs.setString(_mockKey, jsonString);
  }
}
