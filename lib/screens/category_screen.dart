import 'package:flutter/material.dart';
import 'image_selection_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> categories = const [
    {
      'title': 'Erkek Karakterler',
      'icon': Icons.face_retouching_natural,
      'color': Color(0xFF90CAF9),
      'key': 'erkek_karakter',
    },
    {
      'title': 'Kız Karakterler',
      'icon': Icons.face,
      'color': Color(0xFFF48FB1),
      'key': 'kiz_karakter',
    },
    {
      'title': 'Sevimli Dostlar',
      'icon': Icons.pets,
      'color': Color(0xFFA5D6A7),
      'key': 'sevimli_dostlar',
    },
    {
      'title': 'Taşıtlar',
      'icon': Icons.directions_car,
      'color': Color(0xFFFFF59D),
      'key': 'tasitlar',
    },
    {
      'title': 'Sayılar',
      'icon': Icons.pin,
      'color': Color(0xFFB39DDB),
      'key': 'sayilar',
    },
    {
      'title': 'Meyveler & Yiyecekler',
      'icon': Icons.restaurant,
      'color': Color(0xFFFFCC80),
      'key': 'meyveler',
    },
    {
      'title': 'Vahşi Dostlar',
      'icon': Icons.forest,
      'color': Color(0xFF80CBC4),
      'key': 'vahsi_dostlar',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'COLOR WORLD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: Colors.black, height: 4.0),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageSelectionScreen(
                    categoryId: cat['key'],
                    categoryTitle: cat['title'],
                    themeColor: cat['color'],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: cat['color'],
                border: Border.all(color: Colors.black, width: 3.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(cat['icon'], size: 36.0, color: Colors.black),
                  const SizedBox(width: 20.0),
                  Expanded(
                    child: Text(
                      cat['title'].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.black),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
