import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:color_world/screens/category_screen.dart';
import 'package:color_world/billing_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    final billingManager = BillingManager();
    billingManager.initialize();
  }
  
  runApp(const ColorWorldApp());
}

class ColorWorldApp extends StatelessWidget {
  const ColorWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color World',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94E77),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CategoryScreen(),
    );
  }
}
