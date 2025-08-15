class Meal {
  final String id;
  final String name;
  final String category;
  final String instructions;
  final String imageUrl;
  final List<String> ingredients;
  final String? youtubeUrl;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.instructions,
    required this.imageUrl,
    required this.ingredients,
    this.youtubeUrl, 
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      if (json['strIngredient$i'] != null && json['strIngredient$i'].isNotEmpty) {
        ingredients.add(json['strIngredient$i']);
      }
    }
    return Meal(
      id: json['idMeal'],
      name: json['strMeal'],
      category: json['strCategory'] ?? '',
      instructions: json['strInstructions'] ?? '',
      imageUrl: json['strMealThumb'] ?? '',
      ingredients: ingredients,
      youtubeUrl: json['strYoutube'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strInstructions': instructions,
      'strMealThumb': imageUrl,
      'ingredients': ingredients,
      'strYoutube': youtubeUrl, 
    };
  }
}