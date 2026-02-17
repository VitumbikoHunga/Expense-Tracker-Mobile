import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;

    try {
      // Mock data for demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      _categories = [
        Category(
          id: '1',
          name: 'Food',
          icon: 'restaurant',
          color: '#63BE7B',
          userId: 'user_123',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Category(
          id: '2',
          name: 'Transport',
          icon: 'directions_car',
          color: '#FFA500',
          userId: 'user_123',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Category(
          id: '3',
          name: 'Entertainment',
          icon: 'local_movies',
          color: '#8E7CC3',
          userId: 'user_123',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
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

  Future<bool> createCategory(String name, String icon, String color) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final newCategory = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: icon,
        color: color,
        userId: 'user_123',
        createdAt: DateTime.now(),
      );
      
      _categories.insert(0, newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _categories.removeWhere((cat) => cat.id == categoryId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
