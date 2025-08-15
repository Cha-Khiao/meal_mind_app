import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/meal_model.dart';
import '../services/translation_service.dart';
import '../services/history_service.dart';
import '../providers/favorites_provider.dart';
import 'lottie_loading_widget.dart';

class MealDetailPage extends StatefulWidget {
  final Meal meal;
  const MealDetailPage({Key? key, required this.meal}) : super(key: key);

  @override
  _MealDetailPageState createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> with SingleTickerProviderStateMixin {
  Meal? translatedMeal;
  bool isLoading = true;
  final TranslationService translationService = TranslationService();
  final HistoryService historyService = HistoryService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _translateAndLoad();
    _addToHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _translateAndLoad() async {
    try {
      final results = await Future.wait([
        translationService.translateToThai(widget.meal.instructions),
        translationService.translateListToThai(widget.meal.ingredients),
      ]);
      
      final translatedInstructions = results[0] as String;
      final translatedIngredients = results[1] as List<String>;

      if (!mounted) return;
      setState(() {
        translatedMeal = widget.meal.copyWith(
          instructions: translatedInstructions,
          ingredients: translatedIngredients,
        );
        isLoading = false;
      });
    } catch (e) {
      print('Translation error: $e');
      if (!mounted) return;
      setState(() {
        translatedMeal = widget.meal;
        isLoading = false;
      });
    }
  }

  Future<void> _addToHistory() async {
    try {
      await historyService.addToHistory(widget.meal);
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  void _toggleFavorite() {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final isFav = favoritesProvider.isFavorite(widget.meal.id);
    
    isFav 
      ? favoritesProvider.removeFavorite(widget.meal.id)
      : favoritesProvider.addFavorite(widget.meal);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isFav ? 'นำออกจากรายการโปรดแล้ว' : 'เพิ่มในรายการโปรดแล้ว'),
      backgroundColor: isFav ? Colors.orange : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  Future<void> _launchYoutube() async {
    final url = widget.meal.youtubeUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดลิงก์วิดีโอได้'), backgroundColor: Colors.red),
      );
    }
  }

  List<String> _splitInstructions(String instructions) {
    return instructions
        .split(RegExp(r'\r\n|\n'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim().replaceAll(RegExp(r'^\d+\.\s*'), ''))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: isLoading
          ? LottieLoadingWidget(
              message: 'กำลังแปลสูตร "${widget.meal.name}"...',
              animationPath: 'assets/animations/loading_food.json',
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [_buildSliverAppBar()];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildIngredientsTab(),
                  _buildInstructionsTab(),
                ],
              ),
            ),
      bottomNavigationBar: _buildYoutubeButton(),
    );
  }

  Widget _buildSliverAppBar() {
    final favoritesProvider = context.watch<FavoritesProvider>();
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      floating: false,
      elevation: 4,
      backgroundColor: Theme.of(context).primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'meal_${widget.meal.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.meal.imageUrl,
                placeholder: (context, url) => const LottieLoadingWidget(animationPath: 'assets/animations/loading_food.json'),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          widget.meal.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [
            Shadow(color: Colors.black, blurRadius: 4)
          ]),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 48, right: 48, bottom: 56),
      ),
      actions: [
        _glassMorphismContainer(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                favoritesProvider.isFavorite(widget.meal.id) ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(favoritesProvider.isFavorite(widget.meal.id)),
                color: favoritesProvider.isFavorite(widget.meal.id) ? Colors.redAccent : Colors.white,
              ),
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.orangeAccent,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.list_alt_rounded), text: 'ส่วนผสม'),
          Tab(icon: Icon(Icons.soup_kitchen_rounded), text: 'วิธีทำ'),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    final ingredients = translatedMeal?.ingredients ?? widget.meal.ingredients;
    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: ingredients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                       BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,4))
                    ]
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade400),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ingredients[index],
                          style: const TextStyle(
                            fontSize: 16,

                            shadows: [
                              Shadow(
                                offset: Offset(0.5, 0.5),
                                blurRadius: 1.0,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionsTab() {
    final instructionsList = _splitInstructions(translatedMeal?.instructions ?? widget.meal.instructions);
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: instructionsList.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade800,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            instructionsList[index],
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey.shade800,

                              shadows: const [
                                Shadow(
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 1.0,
                                  color: Colors.black12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget? _buildYoutubeButton() {
    if (widget.meal.youtubeUrl == null || widget.meal.youtubeUrl!.isEmpty) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: ElevatedButton.icon(
          onPressed: _launchYoutube,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ดูวิดีโอสอนทำ'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.red.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
  
  Widget _glassMorphismContainer({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

extension MealCopy on Meal {
  Meal copyWith({
    String? id,
    String? name,
    String? category,
    String? instructions,
    String? imageUrl,
    List<String>? ingredients,
    String? youtubeUrl,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
    );
  }
}