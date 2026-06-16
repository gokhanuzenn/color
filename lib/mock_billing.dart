import 'package:shared_preferences/shared_preferences.dart';

class MockBillingManager {
  static const String _adFreeKey = 'is_ad_free';
<<<<<<< HEAD

=======
  
>>>>>>> 66368d638fa4301d088748b02168261eca1c903d
  static Future<bool> isAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adFreeKey) ?? false;
  }

  static Future<void> purchaseAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adFreeKey, true);
  }
}
