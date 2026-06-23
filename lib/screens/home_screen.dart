import 'package:flutter/material.dart';
import 'package:color_world/screens/category_screen.dart';
import 'package:color_world/billing_manager.dart';
import 'package:color_world/utils/localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdFree = false;

  @override
  void initState() {
    super.initState();
    _checkAdFreeStatus();
  }

  Future<void> _checkAdFreeStatus() async {
    final status = await BillingManager.isAdFree();
    setState(() => _isAdFree = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Neubrutalist Logo/Title
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF06D6A0),
                  border: Border.all(color: const Color(0xFF2D2D2D), width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF2D2D2D),
                      offset: Offset(10, 10),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.palette_outlined, size: 80, color: Color(0xFF2D2D2D)),
                    const SizedBox(height: 16),
                    Text(
                      L.appTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D2D2D),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Promo Banner
              if (!_isAdFree)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166),
                    border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2D2D2D),
                        offset: Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    "RuzgarveGoktug2026",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
              // Start Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF476F),
                    border: Border.all(color: const Color(0xFF2D2D2D), width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2D2D2D),
                        offset: Offset(8, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      L.start.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
