import 'package:flutter/material.dart';
import 'package:color_world/screens/image_selection_screen.dart';
import 'package:color_world/mock_billing.dart';
import 'package:color_world/utils/localization.dart';

class ColoringCategory {
  final String id;
  final int count;
  final Color themeColor;
  final IconData icon;

  String get title => L.categoryName(id);

  ColoringCategory({
    required this.id,
    required this.count,
    required this.themeColor,
    required this.icon,
  });
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isAdFree = false;
  final TextEditingController _promoController = TextEditingController();
  final String _validPromoCode = 'RuzgarveGoktug2026';

  static final List<ColoringCategory> categories = [
    ColoringCategory(id: 'animal', count: 20, themeColor: const Color(0xFF6DA9E4), icon: Icons.pets),
    ColoringCategory(id: 'girl', count: 20, themeColor: const Color(0xFFE6A8D7), icon: Icons.face_retouching_natural),
    ColoringCategory(id: 'car', count: 11, themeColor: const Color(0xFFB39EB5), icon: Icons.directions_car),
    ColoringCategory(id: 'number', count: 9, themeColor: const Color(0xFFFFB347), icon: Icons.pin),
    ColoringCategory(id: 'food', count: 11, themeColor: const Color(0xFF98FB98), icon: Icons.restaurant),
    ColoringCategory(id: 'nature', count: 11, themeColor: const Color(0xFFAEC6CF), icon: Icons.nature),
    ColoringCategory(id: 'space', count: 1, themeColor: const Color(0xFF3F51B5), icon: Icons.rocket_launch),
    ColoringCategory(id: 'dino', count: 1, themeColor: const Color(0xFF4CAF50), icon: Icons.pets),
    ColoringCategory(id: 'magic', count: 1, themeColor: const Color(0xFFE91E63), icon: Icons.auto_awesome),
    ColoringCategory(id: 'sea', count: 12, themeColor: const Color(0xFF03A9F4), icon: Icons.water),
    ColoringCategory(id: 'fairy', count: 1, themeColor: const Color(0xFF9C27B0), icon: Icons.fort),
    ColoringCategory(id: 'robot', count: 2, themeColor: const Color(0xFF607D8B), icon: Icons.smart_toy),
    ColoringCategory(id: flower, count: 11, themeColor: const Color(0xFF8BC34A), icon: Icons.local_florist),
    ColoringCategory(id: emoji, count: 1, themeColor: const Color(0xFFFF9800), icon: Icons.mood),
    ColoringCategory(id: hero, count: 1, themeColor: const Color(0xFFE53935), icon: Icons.shield),
    ColoringCategory(id: farm, count: 1, themeColor: const Color(0xFF8D6E63), icon: Icons.agriculture),
    ColoringCategory(id: job, count: 1, themeColor: const Color(0xFF00ACC1), icon: Icons.work),
    ColoringCategory(id: letter, count: 1, themeColor: const Color(0xFFFFD54F), icon: Icons.font_download),
    ColoringCategory(id: 'toy', count: 6, themeColor: const Color(0xFF26A69A), icon: Icons.toys),
    ColoringCategory(id: construction, count: 1, themeColor: const Color(0xFFFFCC00), icon: Icons.construction),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdFreeStatus();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _checkAdFreeStatus() async {
    final status = await MockBillingManager.isAdFree();
    setState(() => _isAdFree = status);
  }

  Future<void> _handlePurchase() async {
    await MockBillingManager.purchaseAdFree();
    await _checkAdFreeStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.adsRemoved)),
      );
    }
  }

  void _showPromoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7),
              border: Border.all(color: const Color(0xFF2D2D2D), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF2D2D2D),
                  offset: Offset(8, 8),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  L.promoCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: L.enterCode,
                    fillColor: Colors.white,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 3),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 3),
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                          ),
                          child: Center(
                            child: Text(
                              L.cancel,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (_promoController.text.trim().toUpperCase() == _validPromoCode.toUpperCase()) {
                            await MockBillingManager.purchaseAdFree();
                            await _checkAdFreeStatus();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(L.codeAccepted)),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(L.invalidCode)),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0),
                            border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                          ),
                          child: Center(
                            child: Text(
                              L.confirm,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        title: Text(
          L.appTitle,
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF2D2D2D)),
            onPressed: _showPromoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isAdFree)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _handlePurchase,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2D2D2D),
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      L.removeAds,
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              L.selectCategory,
              style: const TextStyle(
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
              categoryTitle: category.title,
              themeColor: category.themeColor,
              templateCount: category.count,
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
                      category.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.count} ${L.imagesCount}',
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
