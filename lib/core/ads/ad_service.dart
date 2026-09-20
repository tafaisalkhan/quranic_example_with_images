import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AdIds {
  static const androidBanner = 'ca-app-pub-1852108665659812/7973420361';
  static const androidInterstitial = 'ca-app-pub-1852108665659812/2967760831';
}

class AdsController extends ChangeNotifier {
  AdsController._();

  static final instance = AdsController._();
  static const removeAdsProductId = 'remove_ads';
  static const _entitlementKey = 'remove_ads_entitlement';

  final Random _random = Random();
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  SharedPreferences? _preferences;
  ProductDetails? _removeAdsProduct;
  InterstitialAd? _interstitial;
  int _openCount = 0;
  int _nextInterstitialAt = 2;
  bool _loadingInterstitial = false;
  bool _initialized = false;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  bool _adsRemoved = false;
  String? _purchaseError;

  bool get initialized => _initialized;
  bool get adsRemoved => _adsRemoved;
  bool get storeAvailable => _storeAvailable;
  bool get purchasePending => _purchasePending;
  bool get canPurchase =>
      _storeAvailable && _removeAdsProduct != null && !_purchasePending;
  String? get removeAdsPrice => _removeAdsProduct?.price;
  String? get purchaseError => _purchaseError;

  Future<void> initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    _adsRemoved = _preferences?.getBool(_entitlementKey) ?? false;

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _purchasePending = false;
        _purchaseError = 'Purchase update failed. Please try again.';
        notifyListeners();
      },
    );

    _storeAvailable = await _store.isAvailable();
    if (_storeAvailable) {
      final response = await _store.queryProductDetails(
        const {removeAdsProductId},
      );
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.first;
      } else if (response.error != null) {
        _purchaseError = response.error!.message;
      } else {
        _purchaseError =
            'Product remove_ads is not active for this app in Google Play.';
      }
    } else {
      _purchaseError = 'Google Play purchases are unavailable.';
    }

    if (!_adsRemoved) {
      await MobileAds.instance.initialize();
      _resetThreshold();
      _loadInterstitial();
    }

    _initialized = true;
    notifyListeners();

    if (_storeAvailable) {
      unawaited(restorePurchases(silent: true));
    }
  }

  Future<bool> buyRemoveAds() async {
    final product = _removeAdsProduct;
    if (!_storeAvailable || product == null || _purchasePending) return false;
    _purchasePending = true;
    _purchaseError = null;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _purchasePending = false;
        _purchaseError = 'The Google Play purchase screen could not open.';
        notifyListeners();
      }
      return started;
    } catch (error) {
      _purchasePending = false;
      _purchaseError = 'Unable to start purchase: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases({bool silent = false}) async {
    if (!_storeAvailable || _purchasePending) return;
    if (!silent) {
      _purchasePending = true;
      _purchaseError = null;
      notifyListeners();
    }
    try {
      await _store.restorePurchases();
    } catch (error) {
      _purchasePending = false;
      if (!silent) _purchaseError = 'Unable to restore purchases: $error';
      notifyListeners();
    } finally {
      if (!silent && !_adsRemoved) {
        _purchasePending = false;
        notifyListeners();
      }
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (await _verifyPurchase(purchase)) {
            await _grantRemoveAds();
          } else {
            _purchaseError = 'Google Play could not verify this purchase.';
          }
          _purchasePending = false;
        case PurchaseStatus.error:
          _purchasePending = false;
          _purchaseError = purchase.error?.message ?? 'Purchase failed.';
        case PurchaseStatus.canceled:
          _purchasePending = false;
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // Client-side verification for this offline app. For production fraud
    // resistance, send serverVerificationData to a secure backend and verify
    // the purchase token with the Google Play Developer API before returning.
    return purchase.productID == removeAdsProductId &&
        purchase.verificationData.serverVerificationData.isNotEmpty;
  }

  Future<void> _grantRemoveAds() async {
    if (_adsRemoved) return;
    _adsRemoved = true;
    await _preferences?.setBool(_entitlementKey, true);
    _interstitial?.dispose();
    _interstitial = null;
    _loadingInterstitial = false;
    notifyListeners();
  }

  void _resetThreshold() {
    _openCount = 0;
    _nextInterstitialAt = 2 + _random.nextInt(2);
  }

  void _loadInterstitial() {
    if (!_initialized && _preferences == null) return;
    if (_adsRemoved || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdIds.androidInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          if (_adsRemoved) {
            ad.dispose();
          } else {
            _interstitial = ad;
          }
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    _interstitial?.dispose();
    super.dispose();
  }

  void beforeExampleNavigation(VoidCallback navigate) {
    if (_adsRemoved) {
      navigate();
      return;
    }
    _openCount++;
    final ad = _interstitial;
    if (_openCount < _nextInterstitialAt || ad == null) {
      _loadInterstitial();
      navigate();
      return;
    }

    _interstitial = null;
    _resetThreshold();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _loadInterstitial();
        navigate();
      },
      onAdFailedToShowFullScreenContent: (failedAd, _) {
        failedAd.dispose();
        _loadInterstitial();
        navigate();
      },
    );
    ad.show();
  }
}

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  AdsController get _controller => AdsController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncAdState);
    _syncAdState();
  }

  void _syncAdState() {
    if (_controller.adsRemoved) {
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _loaded = false);
      return;
    }
    if (_controller.initialized && _ad == null) _loadBanner();
  }

  void _loadBanner() {
    final ad = BannerAd(
      adUnitId: AdIds.androidBanner,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted && !_controller.adsRemoved) {
            setState(() => _loaded = true);
          }
        },
        onAdFailedToLoad: (failedAd, _) {
          failedAd.dispose();
          if (identical(_ad, failedAd)) _ad = null;
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncAdState);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (_controller.adsRemoved || !_loaded || ad == null) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: ad.size.height.toDouble(),
        child: Center(
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}
