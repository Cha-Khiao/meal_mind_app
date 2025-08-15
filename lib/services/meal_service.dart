import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_model.dart';

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Meal>> fetchAllMeals() async {
    try {

      final response = await http
          .get(Uri.parse('$_baseUrl/search.php?s='))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List meals = data['meals'] ?? [];
        return meals.map((meal) => Meal.fromJson(meal)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Meal>> fetchMealsByCategory(String category) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/filter.php?c=$category'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List meals = data['meals'] ?? [];
        

        if (category.toLowerCase() == 'beef' && meals.isNotEmpty) {
          List<Meal> detailedMeals = [];
          for (var meal in meals) {
            try {
              final detailResponse = await http
                  .get(Uri.parse('$_baseUrl/lookup.php?i=${meal['idMeal']}'))
                  .timeout(_timeout);
              
              if (detailResponse.statusCode == 200) {
                final detailData = json.decode(detailResponse.body);
                List detailMeals = detailData['meals'] ?? [];
                if (detailMeals.isNotEmpty) {
                  detailedMeals.add(Meal.fromJson(detailMeals[0]));
                }
              }
            } catch (e) {
              print('Error fetching details for meal ${meal['idMeal']}: $e');

              detailedMeals.add(Meal(
                id: meal['idMeal'],
                name: meal['strMeal'] ?? 'Unknown',
                category: category,
                instructions: '',
                imageUrl: meal['strMealThumb'] ?? '',
                ingredients: [],
                youtubeUrl: null,
              ));
            }
          }
          return detailedMeals;
        }
        
        return meals.map((meal) => Meal(
          id: meal['idMeal'],
          name: meal['strMeal'],
          category: category,
          instructions: '',
          imageUrl: meal['strMealThumb'],
          ingredients: [],
          youtubeUrl: null,
        )).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Meal> fetchMealDetail(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/lookup.php?i=$id'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List meals = data['meals'];
        if (meals.isNotEmpty) {
          return Meal.fromJson(meals[0]);
        } else {
          throw Exception('Meal not found');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Meal>> searchMeals(String query) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/search.php?s=$query'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List meals = data['meals'] ?? [];
        return meals.map((meal) => Meal.fromJson(meal)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Meal> getRandomMeal() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/random.php'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List meals = data['meals'];
        if (meals.isNotEmpty) {
          return Meal.fromJson(meals[0]);
        } else {
          throw Exception('Random meal not found');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}