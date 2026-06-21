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
        // categoryId göndererek sadece o kategoriye ait resimleri filtreliyoruz
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

  // BURASI KRİTİK: Dosyaları senin verdiğin isimlendirme formatına göre manuel ekliyoruz.
  // Otomatik tarama yerine bu yöntem %100 çalışır.
  Future<List<String>> _loadImages(String catId) async {
    // Kategori anahtarları ile gerçek dosya adlarının eşleştirilmesi
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
      'dinozor': 22, // Dinozor 22 tane (dinozor_1 to dinozor_22)
      'sevimli_dostlar': 11,
      'vahsi_dostlar': 11,
      'girl': 22,
      'car': 3, // tasitlar_1, tasitlar_2, tasitlar_3 (ayrıca tasitlar_004 vb var ama ana sayı 3 veya sıralı olanlar)
      'number': 10, // sayilar_1 to sayilar_10 (sayilar_0 da var)
      'food': 41,
      'nature': 11,
      'space': 8, // uzay_19 to uzay_26 (ayrıca uzay_001 vb var)
      'sea': 20, // okyanus_1 to okyanus_20
      'robot': 15,
      'emoji': 15,
      'hero': 19, // kahraman_1 to kahraman_19
      'job': 31,
      'letter': 25, // harfler_1 to harfler_25
      'toy': 6, // oyuncak_1 to oyuncak_6
      'construction': 24, // insaat_1 to insaat_24
    };

    int count = counts[catId] ?? 0;
    List<String> images = [];

    // Özel durumlar veya standart sıralı yapılar
    if (catId == 'car') {
      images = [
        'assets/templates/tasitlar_1.png',
        'assets/templates/tasitlar_2.png',
        'assets/templates/tasitlar_3.png',
        'assets/templates/tasitlar_004.png',
        'assets/templates/tasitlar_005.png',
        'assets/templates/tasitlar_006.png',
        'assets/templates/tasitlar_007.png',
        'assets/templates/tasitlar_008.png',
        'assets/templates/tasitlar_009.png',
        'assets/templates/tasitlar_010.png',
        'assets/templates/tasitlar_011.png',
      ];
    } else if (catId == 'number') {
      images = ['assets/templates/sayilar_0.png'];
      for (int i = 1; i <= 10; i++) {
        images.add('assets/templates/sayilar_$i.png');
      }
    } else if (catId == 'space') {
      images = [
        'assets/templates/uzay_001.png',
        'assets/templates/uzay_002.png',
        'assets/templates/uzay_003.png',
        'assets/templates/uzay_004.png',
        'assets/templates/uzay_005.png',
        'assets/templates/uzay_006.png',
        'assets/templates/uzay_007.png',
        'assets/templates/uzay_008.png',
        'assets/templates/uzay_009.png',
        'assets/templates/uzay_010.png',
        'assets/templates/uzay_011.png',
        'assets/templates/uzay_012.png',
        'assets/templates/uzay_013.png',
        'assets/templates/uzay_014.png',
        'assets/templates/uzay_015.png',
        'assets/templates/uzay_016.png',
        'assets/templates/uzay_017.png',
        'assets/templates/uzay_018.png',
        'assets/templates/uzay_19.png',
        'assets/templates/uzay_20.png',
        'assets/templates/uzay_21.png',
        'assets/templates/uzay_22.png',
        'assets/templates/uzay_23.png',
        'assets/templates/uzay_24.png',
        'assets/templates/uzay_25.png',
        'assets/templates/uzay_26.png',
      ];
    } else {
      images = List.generate(count, (index) => 'assets/templates/${filePrefix}_${index + 1}.png');
    }

    return images;
  }
}