import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart'; 

import '../services/meal_service.dart';
import '../providers/favorites_provider.dart';
import 'meal_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MealService mealService = MealService();

  Future<bool> _confirmDismiss(String mealName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการนำ "$mealName" ออกจากรายการโปรดใช่หรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    ) ?? false; 
  }


  void _removeFavorite(String mealId) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    favoritesProvider.removeFavorite(mealId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('นำออกจากรายการโปรดแล้ว'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

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
        child: favoritesProvider.favoriteMeals.isEmpty
            ? _buildEmptyState()
            : _buildFavoritesList(favoritesProvider),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('รายการโปรด'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset( 
            'assets/animations/loader_cat.json',
            width: 250,
            height: 250,
            repeat: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'ยังไม่มีรายการโปรด',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เพิ่มสูตรที่คุณชอบเพื่อดูที่นี่ได้เลย',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('สำรวจสูตรอาหาร'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesProvider favoritesProvider) {
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        await Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
      },
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoritesProvider.favoriteMeals.length,
          itemBuilder: (context, index) {
            final meal = favoritesProvider.favoriteMeals[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildFavoriteItem(meal),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(dynamic meal) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDismiss(meal.name), 
      onDismissed: (_) => _removeFavorite(meal.id),
      background: Container( 
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.red.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('ลบ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_sweep, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            try {
              final detailMeal = await mealService.fetchMealDetail(meal.id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MealDetailPage(meal: detailMeal)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red,
              ));
            }
          },
          child: Row(
            children: [
              Hero(
                tag: 'meal_${meal.id}',
                child: CachedNetworkImage(
                  imageUrl: meal.imageUrl,
                  width: 100, height: 100, fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(meal.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}