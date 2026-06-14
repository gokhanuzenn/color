import 'package:flutter/material.dart';
import 'coloring_canvas_screen.dart';

class ColoringTemplate {
  final String id;
  final String assetPath;
  final String categoryId;

  ColoringTemplate({
    required this.id,
    required this.assetPath,
    required this.categoryId,
  });
}

class ImageSelectionScreen extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;
  final Color themeColor;

  const ImageSelectionScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    required this.themeColor,
  });

  List<ColoringTemplate> _getTemplates() {
    int count = 11;
    String prefix = categoryId;
    if (categoryId == 'sayilar') count = 10;

    return List.generate(count, (index) {
      final numberStr = (index + 1).toString().padLeft(3, '0');
      return ColoringTemplate(
        id: '${prefix}_$numberStr',
        assetPath: 'assets/templates/${prefix}_$numberStr.png',
        categoryId: categoryId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final templates = _getTemplates();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          categoryTitle.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 20,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF000000), width: 4),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF000000), width: 4)),
            ),
            child: const Text(
              'Boyamak istediğin resmi seç',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.0,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return TemplateCard(
                  template: templates[index],
                  themeColor: themeColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TemplateCard extends StatelessWidget {
  final ColoringTemplate template;
  final Color themeColor;

  const TemplateCard({
    super.key,
    required this.template,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ColoringCanvasScreen(
              imagePath: template.assetPath,
              title: template.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(0), // Sharp corners for Neubrutalism
          border: Border.all(color: const Color(0xFF000000), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF000000),
              offset: Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  template.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: themeColor, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          template.id.split('_').last,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF000000)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor,
                  border: Border.all(color: const Color(0xFF000000), width: 3),
                ),
                child: Text(
                  '#${template.id.split('_').last}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF000000)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
