import 'package:flutter/material.dart';
import 'screens/category_screen.dart';

void main() {
  runApp(const ColorWorldApp());
}

class ColorWorldApp extends StatelessWidget {
  const ColorWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color World',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor:
            const Color(0xFFFDFBF7), // Retro-Premium/Neubrutalism Background
        fontFamily: 'Inter', // Assuming Inter for Neubrutalism style
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w900,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF000000),
          ),
        ),
      ),
      home: const CategoryScreen(),
    );
  }
}
