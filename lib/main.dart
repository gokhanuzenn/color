import 'package:flutter/material.dart';
import 'package:color_world/screens/category_screen.dart';

void main() {
  runApp(const ColorWorldApp());
}

class ColorWorldApp extends StatelessWidget {
  const ColorWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color World',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94E77),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CategoryScreen(),
    );
  }
}
