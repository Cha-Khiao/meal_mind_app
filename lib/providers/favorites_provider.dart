import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/favorites_service.dart';

class FavoritesProvider with ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  List<Meal> _favoriteMeals = [];

  List<Meal> get favoriteMeals => _favoriteMeals;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _favoriteMeals = await _favoritesService.getFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(Meal meal) async {
    if (!isFavorite(meal.id)) {
      await _favoritesService.addFavorite(meal);
      _favoriteMeals.add(meal);
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String mealId) async {
    await _favoritesService.removeFavorite(mealId);
    _favoriteMeals.removeWhere((meal) => meal.id == mealId);
    notifyListeners();
  }

  bool isFavorite(String mealId) {
    return _favoriteMeals.any((meal) => meal.id == mealId);
  }
}