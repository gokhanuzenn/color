import 'package:flutter/material.dart';
import 'package:color_world/screens/coloring_canvas_screen.dart';

class ImageSelectionScreen extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;

  const ImageSelectionScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle.toUpperCase())),
      body: FutureBuilder<List<String>>(
        future: _loadImages(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bu kategoride resim bulunamadı."));
          }
          
          final images = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ColoringCanvasScreen(
                    assetPath: images[index], 
                    templateId: images[index].split('/').last,
                  ),
                )),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                  child: Image.asset(images[index], fit: BoxFit.cover),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<String>> _loadImages(String catId) async {
    Map<String, String> prefixMap = {
      'ciftlik': 'ciftlik',
      'dinozor': 'dinozor',
      'sevimli_dostlar': 'sevimli_dostlar',
      'vahsi_dostlar': 'vahsi_dostlar',
      'girl': 'kiz_karakter',
      'car': 'tasitlar',
      'number': 'sayilar',
      'food': 'yiyecekler',
      'nature': 'doga',
      'space': 'uzay',
      'sea': 'okyanus',
      'robot': 'robot',
      'emoji': 'emoji',
      'hero': 'kahraman',
      'job': 'meslekler',
      'letter': 'harfler',
      'toy': 'oyuncak',
      'construction': 'insaat',
    };

    String filePrefix = prefixMap[catId] ?? catId;

    Map<String, int> counts = {
      'ciftlik': 11,
      'dinozor': 22,
      'sevimli_dostlar': 11,
      'vahsi_dostlar': 11,
      'girl': 22,
      'car': 11,
      'number': 11,
      'food': 41,
      'nature': 11,
      'space': 26,
      'sea': 20,
      'robot': 15,
      'emoji': 15,
      'hero': 20,
      'job': 31,
      'letter': 25,
      'toy': 6,
      'construction': 24,
    };

    int count = counts[catId] ?? 0;
    List<String> images = [];

    if (catId == 'car') {
      images = List.generate(11, (index) => 'assets/templates/tasitlar_${index + 1}.png');
    } else if (catId == 'space') {
      images = List.generate(26, (index) {
        int num = index + 1;
        String formatted = num < 10 ? '00$num' : (num < 100 ? '0$num' : '$num');
        return 'assets/templates/uzay_$formatted.png';
      });
    } else {
      images = List.generate(count, (index) => 'assets/templates/${filePrefix}_${index + 1}.png');
    }

    return images;
  }
}