import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal_model.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';

  Future<List<Meal>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson.map((json) => Meal.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addFavorite(Meal meal) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    if (!favorites.any((m) => m.id == meal.id)) {
      favorites.add(meal);
      await prefs.setStringList(
        _favoritesKey,
        favorites.map((meal) => jsonEncode(meal.toJson())).toList(),
      );
    }
  }

  Future<void> removeFavorite(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.removeWhere((meal) => meal.id == mealId);
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((meal) => jsonEncode(meal.toJson())).toList(),
    );
  }

  Future<bool> isFavorite(String mealId) async {
    final favorites = await getFavorites();
    return favorites.any((meal) => meal.id == mealId);
  }
}