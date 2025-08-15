import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';

class HistoryService {
  static const String _historyKey = 'view_history';
  static const int _maxHistoryItems = 20;

  Future<void> addToHistory(Meal meal) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    history.removeWhere((item) => jsonDecode(item)['id'] == meal.id);
    
    history.insert(0, jsonEncode(meal.toJson()));
    
    if (history.length > _maxHistoryItems) {
      history = history.sublist(0, _maxHistoryItems);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  Future<List<Meal>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    return history.map((item) => Meal.fromJson(jsonDecode(item))).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}