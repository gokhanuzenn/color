import 'package:flutter/material.dart';
import 'package:color_world/screens/coloring_canvas_screen.dart';
import 'package:color_world/utils/localization.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryTitle,
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: templateCount,
        itemBuilder: (context, index) {
          final templateId = index + 1;
          final assetPath = 'assets/templates/${categoryId}_$templateId.png';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ColoringCanvasScreen(
                    assetPath: assetPath,
                    templateId: '${categoryId}_$templateId',
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
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Hero(
                          tag: 'template_${categoryId}_$templateId',
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: themeColor.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        border: const Border(
                          top: BorderSide(color: Color(0xFF2D2D2D), width: 2),
                        ),
                      ),
                      child: Text(
                        '#$templateId',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
