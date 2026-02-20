import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

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
    notifyListeners();

    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      _categories = [
        Category(
            id: 'c1',
            name: 'Food',
            icon: 'restaurant',
            color: '#FF5722',
            userId: '1'),
        Category(
            id: 'c2',
            name: 'Transport',
            icon: 'directions_car',
            color: '#2196F3',
            userId: '1'),
      ];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService().get(AppConstants.categoriesEndpoint);
      if (response is List) {
        _categories = response
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['data'] is List) {
        _categories = (response['data'] as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _categories = [];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategory(String name, String icon, String color) async {
    try {
      final data = {
        'name': name,
        'icon': icon,
        'color': color,
      };
      final response = await ApiService().post(
        AppConstants.categoriesEndpoint,
        data: data,
      );
      final created = Category.fromJson(response as Map<String, dynamic>);
      _categories.insert(0, created);
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
      await ApiService()
          .delete('${AppConstants.categoriesEndpoint}/$categoryId');
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
