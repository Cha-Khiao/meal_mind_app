import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _controller;
  Uint8List? _lottieBytes;
  String? _lottieError;

  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.ease),
    );

    _fadeController.forward();
    _scaleController.forward();


    _initLottie();

    _checkAuthAndNavigate();
  }

  Future<void> _initLottie() async {
    try {
      final bytes = await _loadSanitizedLottie('assets/animations/Sushi.json');
      if (!mounted) return;
      setState(() {
        _lottieBytes = bytes;
      });
    } catch (e, st) {
      debugPrint('Sanitize Lottie failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _lottieError = '$e';
      });
    }
  }

  Future<Uint8List> _loadSanitizedLottie(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final dynamic data = jsonDecode(raw);

    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid Lottie JSON root');
    }

    _sanitizeLottieMap(data);

    final fixed = jsonEncode(data);
    return Uint8List.fromList(utf8.encode(fixed));
  }

  void _sanitizeLottieMap(Map<String, dynamic> node) {

    _fixWH(node);

    final layers = node['layers'];
    if (layers is List) {
      for (final l in layers) {
        if (l is Map<String, dynamic>) {
          _fixLayer(l);
        }
      }
    }

    final assets = node['assets'];
    if (assets is List) {
      for (final a in assets) {
        if (a is Map<String, dynamic>) {
          _fixWH(a); 
          final subLayers = a['layers'];
          if (subLayers is List) {
            for (final sl in subLayers) {
              if (sl is Map<String, dynamic>) {
                _fixLayer(sl);
              }
            }
          }
        }
      }
    }
  }

  void _fixLayer(Map<String, dynamic> layer) {

    final ty = layer['ty'];
    final hasRef = layer.containsKey('refId');
    if (ty == 0 || hasRef) {
      _fixWH(layer);
    }
  }

  void _fixWH(Map<String, dynamic> map) {
    final w = map['w'];
    final h = map['h'];

    if (w is num && w is! int) {

      map['w'] = w.round();
    }
    if (h is num && h is! int) {
      map['h'] = h.round();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) =>
            authProvider.isLoggedIn ? HomePage() : LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
            stops: [0.3, 0.8],
          ),
        ),
        child: Stack(
          children: [

            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ShimmerPainter(_shimmerAnimation.value),
                  );
                },
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(size.width * 0.08),
                        child: _buildLottie(size),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.8),
                                    Colors.white,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(
                                    _shimmerAnimation.value - 1.0,
                                    0.0,
                                  ),
                                  end: Alignment(
                                    _shimmerAnimation.value,
                                    0.0,
                                  ),
                                ).createShader(bounds);
                              },
                              child: Text(
                                'สูตรอาหาร',
                                style: TextStyle(
                                  fontSize: size.width * 0.1,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(2, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: size.height * 0.015),
                        Text(
                          'สูตรอาหารแท้',
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(1, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.08),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: size.width * 0.1,
                      height: size.width * 0.1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: size.width * 0.1,
                            height: size.width * 0.1,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                          Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: size.width * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLottie(Size size) {
    if (_lottieError != null) {
      return Icon(
        Icons.restaurant_menu,
        size: size.width * 0.25,
        color: Colors.white,
      );
    }

    if (_lottieBytes == null) {
      return Center(
        child: SizedBox(
          width: size.width * 0.15,
          height: size.width * 0.15,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Lottie.memory(
      _lottieBytes!,
      controller: _controller,
      fit: BoxFit.contain,
      frameRate: FrameRate.max,
      options: LottieOptions(
        enableMergePaths: true,
      ),
      onLoaded: (composition) {
        debugPrint('Lottie loaded: ${composition.duration}');
        _controller
          ..duration = composition.duration
          ..repeat(); 
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lottie error: $error');
        return Icon(
          Icons.restaurant_menu,
          size: size.width * 0.25,
          color: Colors.white,
        );
      },
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double shimmerValue;

  ShimmerPainter(this.shimmerValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.05),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(shimmerValue - 1.0, 0.0),
      end: Alignment(shimmerValue, 0.0),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.shimmerValue != shimmerValue;
  }
}