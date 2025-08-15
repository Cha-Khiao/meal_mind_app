import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../services/meal_service.dart';
import '../providers/favorites_provider.dart';
import 'meal_detail_page.dart';
import 'lottie_loading_widget.dart';
import '../models/meal_model.dart';

class MealsByCategoryPage extends StatefulWidget {
  final String category;
  const MealsByCategoryPage({Key? key, required this.category})
    : super(key: key);

  @override
  _MealsByCategoryPageState createState() => _MealsByCategoryPageState();
}

class _MealsByCategoryPageState extends State<MealsByCategoryPage> {
  late Future<List<Meal>> _mealsFuture;
  final MealService _mealService = MealService();

  @override
  void initState() {
    super.initState();
    _mealsFuture = _loadMeals();
  }

  Future<List<Meal>> _loadMeals() {
    return _mealService.fetchMealsByCategory(widget.category);
  }

  Future<void> _refreshMeals() async {
    setState(() {
      _mealsFuture = _loadMeals();
    });
  }

  void _toggleFav(Meal meal) {
    final fav = context.read<FavoritesProvider>();
    final isFav = fav.isFavorite(meal.id);
    isFav ? fav.removeFavorite(meal.id) : fav.addFavorite(meal);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? 'นำ ${meal.name} ออกจากรายการโปรดแล้ว'
              : 'เพิ่ม ${meal.name} ในรายการโปรดแล้ว',
        ),
        backgroundColor: isFav ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.blue.shade200.withOpacity(0.2),
              Colors.white.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Meal>>(
          future: _mealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LottieLoadingWidget(
                message: 'กำลังโหลดสูตรอาหารหมวดหมู่ ${widget.category}...',
                animationPath: 'assets/animations/loading_food.json',
              );
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return _buildMealGrid(snapshot.data!);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('หมวดหมู่: ${widget.category}'),

      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshMeals,
          tooltip: 'รีเฟรชข้อมูล',
        ),
      ],
    );
  }

  Widget _buildMealGrid(List<Meal> meals) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    return RefreshIndicator.adaptive(
      onRefresh: _refreshMeals,
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
                0.8, // 🎨 IMPROVEMENT: ใช้สัดส่วนเดียวกับ HomePage
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _mealCard(
                    meal,
                    favoritesProvider,
                  ), // ✨ NEW: เรียกใช้ _mealCard ที่ออกแบบใหม่
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mealCard(Meal meal, FavoritesProvider fav) {
    return Card(
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          try {
            final detail = await _mealService.fetchMealDetail(meal.id);
            if (!mounted) return;
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: MealDetailPage(meal: detail),
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Hero(
              tag: 'meal_${meal.id}',
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl,
                placeholder: (_, __) => const LottieLoadingWidget(
                  animationPath: 'assets/animations/loading_food.json',
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _glassMorphismContainer(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      fav.isFavorite(meal.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(fav.isFavorite(meal.id)),
                      color: fav.isFavorite(meal.id)
                          ? Colors.redAccent
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () => _toggleFav(meal),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _glassMorphismContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      meal.category.isNotEmpty
                          ? meal.category.toUpperCase()
                          : widget.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    isPill: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassMorphismContainer({
    required Widget child,
    EdgeInsets? padding,
    bool isPill = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isPill ? 50 : 12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isPill ? 50 : 12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshMeals,
              label: const Text('ลองใหม่อีกครั้ง'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'ไม่พบสูตรอาหาร',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่พบข้อมูลในหมวดหมู่นี้',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshMeals,
            child: const Text('ลองรีเฟรช'),
          ),
        ],
      ),
    );
  }
}
