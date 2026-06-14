import 'package:flutter/material.dart';
import 'package:color_world/screens/image_selection_screen.dart';

class ColoringCategory {
  final String id;
  final String titleTurkish;
  final int count;
  final Color themeColor;
  final IconData icon;

  ColoringCategory({
    required this.id,
    required this.titleTurkish,
    required this.count,
    required this.themeColor,
    required this.icon,
  });
}

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final List<ColoringCategory> categories = [
    ColoringCategory(id: 'erkek_karakter', titleTurkish: 'Erkek Karakterler', count: 11, themeColor: const Color(0xFF6DA9E4), icon: Icons.face),
    ColoringCategory(id: 'kiz_karakter', titleTurkish: 'Kız Karakterler', count: 11, themeColor: const Color(0xFFE6A8D7), icon: Icons.face_retouching_natural),
    ColoringCategory(id: 'sevimli_dostlar', titleTurkish: 'Sevimli Dostlar', count: 11, themeColor: const Color(0xFFFFD1DC), icon: Icons.pets),
    ColoringCategory(id: 'tasitlar', titleTurkish: 'Taşıtlar', count: 11, themeColor: const Color(0xFFB39EB5), icon: Icons.directions_car),
    ColoringCategory(id: 'sayilar', titleTurkish: 'Sayılar', count: 10, themeColor: const Color(0xFFFFB347), icon: Icons.pin),
    ColoringCategory(id: 'meyveler', titleTurkish: 'Meyveler & Yiyecekler', count: 11, themeColor: const Color(0xFF98FB98), icon: Icons.restaurant),
    ColoringCategory(id: 'vahsi_dostlar', titleTurkish: 'Vahşi Dostlar', count: 11, themeColor: const Color(0xFFAEC6CF), icon: Icons.nature),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'BOYAMA DÜNYASI',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Kategori Selectin',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return CategoryCard(category: categories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final ColoringCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageSelectionScreen(
              categoryId: category.id,
              categoryTitle: category.titleTurkish,
              themeColor: category.themeColor,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2D2D2D),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: category.themeColor.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      category.icon,
                      size: 64,
                      color: category.themeColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF2D2D2D), width: 3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      category.titleTurkish.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.count} GÖRSEL',
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
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
