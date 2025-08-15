import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

import '../services/history_service.dart';
import '../services/meal_service.dart';
import 'meal_detail_page.dart';
import '../models/meal_model.dart';
import 'lottie_loading_widget.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  final MealService _mealService = MealService();
  
  late Future<List<Meal>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }
  
  Future<List<Meal>> _loadHistory() async {
    return _historyService.getHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _loadHistory();
    });
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการล้างประวัติ'),
          content: const Text('คุณต้องการล้างประวัติการดูทั้งหมดใช่หรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ล้างประวัติ'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      _refreshHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ล้างประวัติเรียบร้อยแล้ว'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          future: _historyFuture,
          builder: (context, snapshot) {
            final hasHistory = snapshot.hasData && snapshot.data!.isNotEmpty;
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildAppBar(hasHistory),
              body: _buildBody(snapshot),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasHistory) {
    return AppBar(
      title: const Text('ประวัติการดู'),
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
        if (hasHistory)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmClearHistory,
            tooltip: 'ล้างประวัติทั้งหมด',
          ),
      ],
    );
  }

  Widget _buildBody(AsyncSnapshot<List<Meal>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LottieLoadingWidget(
        message: 'กำลังโหลดประวัติ...',
        animationPath: 'assets/animations/loading_food.json',
      );
    }
    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return _buildEmptyState();
    }
    return _buildHistoryList(snapshot.data!);
  }
  
  Widget _buildHistoryList(List<Meal> history) {
    return RefreshIndicator.adaptive(
      onRefresh: () async => _refreshHistory(),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final meal = history[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildHistoryItem(meal),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Meal meal) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          try {
            final detailMeal = await _mealService.fetchMealDetail(meal.id);
            if (mounted) {
              await Navigator.push(context, MaterialPageRoute(
                builder: (context) => MealDetailPage(meal: detailMeal)
              ));
              _refreshHistory();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red,
              ));
            }
          }
        },
        child: Row(
          children: [
            Hero(
              tag: 'meal_${meal.id}', 
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl,
                width: 100, height: 100, fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 100, height: 100, color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
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
            'ยังไม่มีประวัติการดู',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'สูตรอาหารที่คุณดูจะปรากฏที่นี่',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
          const SizedBox(height: 20),
          const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
            label: const Text('ลองใหม่อีกครั้ง'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, 
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }
}