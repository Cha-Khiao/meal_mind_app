import 'dart:ui'; 

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../services/meal_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/drawer_provider.dart';
import '../providers/auth_provider.dart';
import '../models/meal_model.dart';
import 'meal_detail_page.dart';
import 'favorites_page.dart';
import 'lottie_loading_widget.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MealService _mealService = MealService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<List<Meal>> _futureMeals;
  List<Meal> _all = [];
  List<Meal> _filtered = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _futureMeals = _fetchMeals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DrawerProvider>().setIndex(0);
    });
  }

  Future<List<Meal>> _fetchMeals() async {
    return _mealService.fetchAllMeals();
  }

  void _filter(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? List.from(_all)
          : _all.where((m) => m.name.toLowerCase().contains(query)).toList();
    });
  }

  void _toggleFav(Meal m) {
    final fav = context.read<FavoritesProvider>();
    final isFav = fav.isFavorite(m.id);
    isFav ? fav.removeFavorite(m.id) : fav.addFavorite(m);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav
            ? 'นำ ${m.name} ออกจากรายการโปรดแล้ว'
            : 'เพิ่ม ${m.name} ในรายการโปรดแล้ว'),
        backgroundColor: isFav ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _showRandom() async {
    try {
      final meal = await _mealService.getRandomMeal();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MealDetailPage(meal: meal)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถดึงสูตรสุ่มได้: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesProvider>();
    final drawer = context.watch<DrawerProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: _buildAppBar(fav),
      drawer: _buildDrawer(drawer, auth),
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
          future: _futureMeals,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LottieLoadingWidget(
                message: 'กำลังโหลดสูตรอาหารทั้งหมด...',
                animationPath: 'assets/animations/loading_food.json');
            }
            if (snap.hasError) return _errorSection(snap.error);
            if (!snap.hasData || snap.data!.isEmpty) return _noDataSection();

            _all = snap.data!;
            if (!_isSearching) {
              _filtered = List.from(_all);
            }

            return RefreshIndicator.adaptive(
              onRefresh: () async {
                setState(() {
                  _futureMeals = _fetchMeals();
                });
                await context.read<FavoritesProvider>().loadFavorites();
              },
              child: _filtered.isEmpty
                ? _noSearchResultSection()
                : AnimationLimiter(
                    child: GridView.builder(
                      key: const PageStorageKey('home_grid'),
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8, 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final meal = _filtered[i];
                        return AnimationConfiguration.staggeredGrid(
                          position: i,
                          duration: const Duration(milliseconds: 500),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(child: _mealCard(meal, fav)),
                          ),
                        );
                      },
                    ),
                  ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(FavoritesProvider fav) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    title: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: _isSearching
          ? _searchField()
          : const Text('สูตรอาหารแนะนำ', key: ValueKey('title')),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.category_outlined),
        onPressed: () => Navigator.pushNamed(context, '/categories'),
        tooltip: 'หมวดหมู่อาหาร'),
      _favoriteIcon(fav),
      IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              _isSearching ? Icons.close : Icons.search,
              key: ValueKey(_isSearching),
            ),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                 _searchCtrl.clear();
                 _filter('');
              }
            });
          }),
    ],
  );

  Widget _searchField() => Container(
    key: const ValueKey('search_field'),
    height: 40,
    child: TextField(
      controller: _searchCtrl,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'ค้นหาสูตรอาหาร...',
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: _filter,
    ),
  );

  Widget _favoriteIcon(FavoritesProvider fav) => Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.favorite_outline),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage())),
          tooltip: 'รายการโปรด',
        ),
        if (fav.favoriteMeals.isNotEmpty)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('${fav.favoriteMeals.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )),
      ],
    ),
  );

  Widget _buildFAB() => FloatingActionButton(
      onPressed: _showRandom,
      tooltip: 'สุ่มสูตร',
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.deepOrange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.shuffle, color: Colors.white),
      ),
    );

  Widget _mealCard(Meal meal, FavoritesProvider fav) => Card(
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
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Hero(
            tag: 'meal_${meal.id}',
            child: CachedNetworkImage(
                imageUrl: meal.imageUrl,
                placeholder: (_, __) => const LottieLoadingWidget(animationPath: 'assets/animations/loading_food.json'),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
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
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    fav.isFavorite(meal.id) ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(fav.isFavorite(meal.id)),
                    color: fav.isFavorite(meal.id) ? Colors.redAccent : Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    meal.category.isNotEmpty ? meal.category.toUpperCase() : 'UNCATEGORIZED',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1,1))]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );

  Widget _glassMorphismContainer({required Widget child, EdgeInsets? padding, bool isPill = false}) {
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

  Widget _errorSection(Object? e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Text('$e', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _futureMeals = _fetchMeals()),
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

  Widget _noDataSection() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.no_food_outlined, size: 64, color: Colors.orange),
      const SizedBox(height: 16),
      Text('ไม่พบข้อมูลสูตรอาหาร', style: TextStyle(fontSize: 18, color: Colors.orange.shade800)),
    ]),
  );

  Widget _noSearchResultSection() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.search_off_rounded, size: 64, color: Colors.orange),
      const SizedBox(height: 16),
      Text('ไม่พบสูตรอาหารที่ค้นหา', style: TextStyle(fontSize: 18, color: Colors.orange.shade800)),
      const SizedBox(height: 8),
      Text('ลองใช้คำค้นหาอื่นดูสิ', style: TextStyle(color: Colors.grey.shade600)),
    ]),
  );

  Drawer _buildDrawer(DrawerProvider d, AuthProvider auth) => Drawer(
    child: Column(
      children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _buildDrawerHeader(auth),
            _dItem(Icons.home_outlined, 'หน้าแรก', 0, d, () {
            }),
            _dItem(Icons.favorite_outline, 'รายการโปรด', 1, d, () =>
                Navigator.pushNamed(context, '/favorites')),
            _dItem(Icons.category_outlined, 'หมวดหมู่', 2, d, () =>
                Navigator.pushNamed(context, '/categories')),
            _dItem(Icons.shuffle, 'สุ่มสูตร', 3, d, _showRandom),
            const Divider(indent: 16, endIndent: 16),
            _dItem(Icons.history, 'ประวัติการดู', 4, d, () =>
                Navigator.pushNamed(context, '/history')),
            _dItem(Icons.info_outline, 'เกี่ยวกับเรา', 5, d, () =>
                Navigator.pushNamed(context, '/about')),
          ]),
        ),
        const Divider(height: 1),
        _dItem(Icons.logout, 'ออกจากระบบ', -1, d, () async { 
          await auth.logout();
          Navigator.pushReplacementNamed(context, '/login');
        }),
        const SizedBox(height: 20),
      ],
    ),
  );

  Widget _buildDrawerHeader(AuthProvider auth) {
    final user = auth.user;
    final hasPhoto = user?.photoURL != null && user!.photoURL!.isNotEmpty;

    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withOpacity(0.8), Colors.orangeAccent.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16, left: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage: hasPhoto ? CachedNetworkImageProvider(user.photoURL!) : null,
                    child: !hasPhoto
                        ? const Icon(Icons.person, size: 30, color: Colors.orange)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.name ?? 'ผู้ใช้ทั่วไป',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 2)]),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _dItem(IconData ic, String txt, int idx, DrawerProvider d, VoidCallback tap) {
    final isSelected = d.selectedIndex == idx;
    return Material(
      color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(ic, color: isSelected ? Colors.orange : Colors.grey.shade600),
        title: Text(txt, style: TextStyle(
            color: isSelected ? Colors.orange.shade800 : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          if (idx != d.selectedIndex) {
             d.setIndex(idx);
             Future.delayed(const Duration(milliseconds: 250), tap);
          }
        },
      ),
    );
  }
}