import 'package:flutter/material.dart';
import 'package:color_world/screens/ad_transition_screen.dart';
import 'package:color_world/utils/localization.dart';

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
  final int templateCount;

  const ImageSelectionScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    required this.themeColor,
    required this.templateCount,
  });

  List<ColoringTemplate> _getTemplates() {
    String prefix = categoryId;
    return List.generate(templateCount, (index) {
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          categoryTitle.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D), width: 3)),
            ),
            child: Text(
              L.selectImageToColor,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF2D2D2D).withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
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
            builder: (context) => AdTransitionScreen(
              assetPath: template.assetPath,
              templateId: template.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2D2D2D),
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(13),
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
                        Icon(Icons.image_outlined, color: themeColor.withOpacity(0.5), size: 40),
                        const SizedBox(height: 8),
                        Text(
                          template.id.split('_').last,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
                ),
                child: Text(
                  '#${template.id.split('_').last}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
