import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingManager {
  static const String _adFreeKey = 'is_ad_free';
  static const String _adFreeProductId = 'ad_free_upgrade';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static final BillingManager _instance = BillingManager._internal();
  factory BillingManager() => _instance;
  BillingManager._internal();

  void initialize() {
    if (kIsWeb) return;
    
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      // handle error here
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  static Future<bool> isAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adFreeKey) ?? false;
  }

  Future<void> purchaseAdFree() async {
    if (kIsWeb) return;

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> kIds = <String>{_adFreeProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
    
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_adFreeKey, true);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    });
  }
}
