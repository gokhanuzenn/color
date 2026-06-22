import 'package:flutter/material.dart';
import 'package:color_world/screens/image_selection_screen.dart';
import 'package:color_world/mock_billing.dart';
import 'package:color_world/utils/localization.dart';
import 'package:audioplayers/audioplayers.dart';

class ColoringCategory {
  final String id;
  final int count;
  final Color themeColor;
  final IconData icon;
  String? titleOverride;

  String get title => titleOverride ?? L.categoryName(id);

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

  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMusicOn = true;

  static final List<ColoringCategory> categories = [
    ColoringCategory(id: 'ciftlik', count: 11, themeColor: const Color(0xFF8D6E63), icon: Icons.agriculture)..titleOverride = 'Çiftlik',
    ColoringCategory(id: 'dinozor', count: 15, themeColor: const Color(0xFF4CAF50), icon: Icons.pets)..titleOverride = 'Dinozorlar',
    ColoringCategory(id: 'sevimli_dostlar', count: 11, themeColor: const Color(0xFF6DA9E4), icon: Icons.pets)..titleOverride = 'Sevimli Dostlar',
    ColoringCategory(id: 'vahsi_dostlar', count: 11, themeColor: const Color(0xFFE53935), icon: Icons.nature_people)..titleOverride = 'Vahşi Dostlar',
    ColoringCategory(id: 'girl', count: 22, themeColor: const Color(0xFFE6A8D7), icon: Icons.face_retouching_natural)..titleOverride = 'Kız Karakterler',
    ColoringCategory(id: 'car', count: 11, themeColor: const Color(0xFFB39EB5), icon: Icons.directions_car)..titleOverride = 'Taşıtlar',
    ColoringCategory(id: 'number', count: 11, themeColor: const Color(0xFFFFB347), icon: Icons.pin)..titleOverride = 'Sayılar',
    ColoringCategory(id: 'food', count: 41, themeColor: const Color(0xFF98FB98), icon: Icons.restaurant)..titleOverride = 'Yiyecekler',
    ColoringCategory(id: 'nature', count: 11, themeColor: const Color(0xFFAEC6CF), icon: Icons.nature)..titleOverride = 'Doğa',
    ColoringCategory(id: 'space', count: 26, themeColor: const Color(0xFF3F51B5), icon: Icons.rocket_launch)..titleOverride = 'Uzay',
    ColoringCategory(id: 'sea', count: 20, themeColor: const Color(0xFF03A9F4), icon: Icons.water)..titleOverride = 'Okyanus / Deniz',
    ColoringCategory(id: 'robot', count: 15, themeColor: const Color(0xFF607D8B), icon: Icons.smart_toy)..titleOverride = 'Robotlar',
    ColoringCategory(id: 'emoji', count: 15, themeColor: const Color(0xFFFF9800), icon: Icons.mood)..titleOverride = 'Emojiler',
    ColoringCategory(id: 'hero', count: 20, themeColor: const Color(0xFFE53935), icon: Icons.shield)..titleOverride = 'Erkek Kahramanlar',
    ColoringCategory(id: 'job', count: 31, themeColor: const Color(0xFF00ACC1), icon: Icons.work)..titleOverride = 'Meslekler',
    ColoringCategory(id: 'letter', count: 25, themeColor: const Color(0xFFFFD54F), icon: Icons.font_download)..titleOverride = 'Harfler',
    ColoringCategory(id: 'toy', count: 6, themeColor: const Color(0xFF26A69A), icon: Icons.toys)..titleOverride = 'Oyuncaklar',
    ColoringCategory(id: 'construction', count: 24, themeColor: const Color(0xFFFFCC00), icon: Icons.construction)..titleOverride = 'İnşaat',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdFreeStatus();
    _startBackgroundMusic();
  }

  void _navigateToSelection(ColoringCategory category) {
    _playClickSound();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageSelectionScreen(
          categoryId: category.id,
          categoryTitle: category.title,
          // Artık count göndermiyoruz, kod otomatik sayacak
        ),
      ),
    );
  }

  Future<void> _startBackgroundMusic() async {
    _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('audio/bg_music.mp3'));
  }

  Future<void> _playClickSound() async {
    await _sfxPlayer.play(AssetSource('audio/pop.mp3'));
  }

  void _toggleMusic() {
    setState(() {
      _isMusicOn = !_isMusicOn;
      if (_isMusicOn) {
        _bgMusicPlayer.resume();
      } else {
        _bgMusicPlayer.pause();
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    _bgMusicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkAdFreeStatus() async {
    final status = await MockBillingManager.isAdFree();
    setState(() => _isAdFree = status);
  }

  Future<void> _handlePurchase() async {
    _playClickSound();
    await MockBillingManager.purchaseAdFree();
    await _checkAdFreeStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.adsRemoved)));
    }
  }

  void _showPromoDialog() {
    _playClickSound();
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
              boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(8, 8), blurRadius: 0)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L.promoCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D))),
                const SizedBox(height: 20),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: L.enterCode,
                    fillColor: Colors.white,
                    filled: true,
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D2D2D), width: 3)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D2D2D), width: 3)),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _playClickSound();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF2D2D2D), width: 3)),
                          child: Center(child: Text(L.cancel, style: const TextStyle(fontWeight: FontWeight.w900))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          _playClickSound();
                          if (_promoController.text.trim().toUpperCase() == _validPromoCode.toUpperCase()) {
                            await MockBillingManager.purchaseAdFree();
                            await _checkAdFreeStatus();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.codeAccepted)));
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.invalidCode)));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFF06D6A0), border: Border.all(color: const Color(0xFF2D2D2D), width: 3)),
                          child: Center(child: Text(L.confirm, style: const TextStyle(fontWeight: FontWeight.w900))),
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
        title: Text(L.appTitle, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(_isMusicOn ? Icons.music_note : Icons.music_off, color: const Color(0xFF2D2D2D), size: 28),
            onPressed: _toggleMusic,
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(L.selectCategory, style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategoryCard(
                  category: categories[index], 
                  onTapCard: () => _navigateToSelection(categories[index]),
                ),
                childCount: categories.length,
              ),
            ),
          ),
          // [DÜZELTME] Butonlar listenin en sonuna alındı, taşma hatası yapmaması için sütun (Column) yapısına çevrildi!
          if (!_isAdFree)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                color: const Color(0xFFFDFBF7),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handlePurchase,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                          boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Color(0xFF2D2D2D), size: 18),
                            SizedBox(width: 6),
                            Text("REKLAMLARI SİL (\$2.99)", style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showPromoDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                          boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, color: Color(0xFF2D2D2D), size: 18),
                            SizedBox(width: 6),
                            Text("KOD KULLAN", style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final ColoringCategory category;
  final VoidCallback onTapCard;

  const CategoryCard({super.key, required this.category, required this.onTapCard});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
          boxShadow: const [BoxShadow(color: Color(0xFF2D2D2D), offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: category.themeColor.withOpacity(0.3),
                  child: Center(child: Icon(category.icon, size: 64, color: category.themeColor.withOpacity(0.8))),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 3))),
                child: Column(
                  children: [
                    Text(category.title.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${category.count} ${L.imagesCount}', style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold, fontSize: 10)),
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