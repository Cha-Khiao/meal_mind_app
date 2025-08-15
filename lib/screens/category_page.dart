import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'meals_by_category_page.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  Category({required this.name, required this.icon, required this.color});
}

class CategoryPage extends StatelessWidget {
  final List<Category> categories = [
    Category(name: 'Beef', icon: Icons.kebab_dining, color: Colors.brown),
    Category(name: 'Chicken', icon: Icons.lunch_dining, color: Colors.orange),
    Category(name: 'Dessert', icon: Icons.cake, color: Colors.pinkAccent),
    Category(name: 'Lamb', icon: Icons.set_meal, color: Colors.redAccent),
    Category(
      name: 'Miscellaneous',
      icon: Icons.fastfood,
      color: Colors.blueGrey,
    ),
    Category(
      name: 'Pasta',
      icon: Icons.dinner_dining,
      color: Colors.amber.shade700,
    ),
    Category(name: 'Pork', icon: Icons.restaurant, color: Colors.deepOrange),
    Category(
      name: 'Seafood',
      icon: Icons.set_meal,
      color: Colors.blue.shade700,
    ),
    Category(name: 'Side', icon: Icons.room_service, color: Colors.teal),
    Category(name: 'Starter', icon: Icons.tapas, color: Colors.purple),
    Category(name: 'Vegan', icon: Icons.eco, color: Colors.lightGreen.shade600),
    Category(name: 'Vegetarian', icon: Icons.grass, color: Colors.green),
    Category(
      name: 'Breakfast',
      icon: Icons.breakfast_dining,
      color: Colors.yellow.shade800,
    ),
    Category(name: 'Goat', icon: Icons.pets, color: Colors.brown.shade400),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.blue.shade200.withOpacity(0.2),
              Colors.white.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildCategoryCard(context, category),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('หมวดหมู่อาหาร'),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MealsByCategoryPage(category: category.name),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [category.color.withOpacity(0.7), category.color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: category.color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  category.icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(category.icon, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
