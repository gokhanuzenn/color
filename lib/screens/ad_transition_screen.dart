import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:color_world/screens/coloring_canvas_screen.dart';
import 'package:color_world/mock_billing.dart';
import 'package:color_world/utils/localization.dart';

class AdTransitionScreen extends StatefulWidget {
  final String assetPath;
  final String templateId;

  const AdTransitionScreen({
    super.key,
    required this.assetPath,
    required this.templateId,
  });

  @override
  State<AdTransitionScreen> createState() => _AdTransitionScreenState();
}

class _AdTransitionScreenState extends State<AdTransitionScreen> {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isCheckingBilling = true;

  // Google Test Interstitial Ad Unit ID
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final adFree = await MockBillingManager.isAdFree();
    if (!mounted) return;

    if (adFree) {
      _navigateToCanvas();
    } else {
      setState(() => _isCheckingBilling = false);
      _loadInterstitialAd();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _interstitialAd = ad;
            _isAdLoaded = true;
          });
          _showInterstitialAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _navigateToCanvas();
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _navigateToCanvas();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _navigateToCanvas();
      },
    );

    _interstitialAd!.show();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _navigateToCanvas() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ColoringCanvasScreen(
          assetPath: widget.assetPath,
          templateId: widget.templateId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingBilling) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFBF7),
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.brush_rounded,
                      size: 64,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L.loadingAd,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdLoaded ? L.ready : L.preparingImage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                strokeWidth: 8,
                color: Colors.black,
                backgroundColor: Colors.black12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
