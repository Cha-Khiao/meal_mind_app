import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/favorites_provider.dart';
import 'providers/drawer_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/favorites_page.dart';
import 'screens/home_page.dart';
import 'screens/category_page.dart';
import 'screens/about_page.dart';
import 'screens/history_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ChangeNotifierProvider(create: (context) => DrawerProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'สูตรอาหาร',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Prompt',
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Prompt',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.orange.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/favorites': (context) => FavoritesPage(),
        '/home': (context) => HomePage(),
        '/categories': (context) => CategoryPage(),
        '/about': (context) => AboutPage(),
        '/history': (context) => HistoryPage(),
      },
    );
  }
}