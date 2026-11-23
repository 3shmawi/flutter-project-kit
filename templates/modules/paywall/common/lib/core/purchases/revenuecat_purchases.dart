import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// [PurchasesService] on RevenueCat (App Store + Google Play billing).
/// The SDK keys are public (`appl_…` / `goog_…`) and come from the env
/// file; nothing secret is in the app. Products, offerings and the
/// `premium` entitlement are set up in the RevenueCat dashboard
/// (docs/features/paywall.md).
class RevenueCatPurchasesService implements PurchasesService {
  RevenueCatPurchasesService();

  static const appleApiKey = String.fromEnvironment('REVENUECAT_APPLE_API_KEY');
  static const googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
  );

  static String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => appleApiKey,
    TargetPlatform.android => googleApiKey,
    _ => '',
  };

  bool _configured = false;

  @override
  Future<void> start() async {
    if (kIsWeb || _apiKey.isEmpty) {
      debugPrint('Purchases off: no RevenueCat key for this platform');
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_update);
      _update(await Purchases.getCustomerInfo());
      // @@if auth
      // Purchases follow the account across devices.
      Auth.user.addListener(_syncUser);
      _syncUser();
      // @@endif
    } on PlatformException catch (error, stackTrace) {
      unawaited(Monitoring.captureException(error, stackTrace));
    }
  }

  static void _update(CustomerInfo info) => Premium.active.value = info
      .entitlements
      .active
      .containsKey(Premium.entitlement);
  // @@if auth

  String? _syncedUserId;

  void _syncUser() {
    final id = Auth.user.value?.id;
    if (id == _syncedUserId) return;
    _syncedUserId = id;
    unawaited(_logInOrOut(id));
  }

  static Future<void> _logInOrOut(String? id) async {
    try {
      if (id != null) {
        _update((await Purchases.logIn(id)).customerInfo);
      } else if (!await Purchases.isAnonymous) {
        _update(await Purchases.logOut());
      }
    } on PlatformException catch (error, stackTrace) {
      unawaited(Monitoring.captureException(error, stackTrace));
    }
  }
  // @@endif

  Future<Result<T>> _call<T>(Future<T> Function() action) {
    if (!_configured) {
      return Future.value(
        const Failed(PurchaseFailure(PurchaseFailureReason.notConfigured)),
      );
    }
    return guard(() async {
      try {
        return await action();
      } on PlatformException catch (error) {
        throw _failure(error);
      }
    }, retries: 0);
  }

  static AppFailure _failure(PlatformException error) =>
      switch (PurchasesErrorHelper.getErrorCode(error)) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseFailure(
          PurchaseFailureReason.cancelled,
          error,
        ),
        PurchasesErrorCode.paymentPendingError => PurchaseFailure(
          PurchaseFailureReason.pending,
          error,
        ),
        PurchasesErrorCode.purchaseNotAllowedError ||
        PurchasesErrorCode.insufficientPermissionsError => PurchaseFailure(
          PurchaseFailureReason.notAllowed,
          error,
        ),
        PurchasesErrorCode.productAlreadyPurchasedError => PurchaseFailure(
          PurchaseFailureReason.alreadyOwned,
          error,
        ),
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError => NetworkFailure(error),
        PurchasesErrorCode.configurationError ||
        PurchasesErrorCode.invalidCredentialsError => PurchaseFailure(
          PurchaseFailureReason.notConfigured,
          error,
        ),
        _ => PurchaseFailure(PurchaseFailureReason.storeProblem, error),
      };

  static PlanPeriod _period(PackageType type) => switch (type) {
    PackageType.weekly => PlanPeriod.weekly,
    PackageType.monthly => PlanPeriod.monthly,
    PackageType.annual => PlanPeriod.annual,
    PackageType.lifetime => PlanPeriod.lifetime,
    _ => PlanPeriod.other,
  };

  @override
  Future<Result<List<PaywallPlan>>> plans() => _call(() async {
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const [];
    final plans = [
      for (final package in packages)
        PaywallPlan(
          id: package.identifier,
          period: _period(package.packageType),
          title: package.storeProduct.title,
          price: package.storeProduct.priceString,
          handle: package,
        ),
    ]..sort((a, b) => a.period.index.compareTo(b.period.index));
    return plans;
  });

  @override
  Future<Result<void>> buy(PaywallPlan plan) => _call(() async {
    final package = plan.handle;
    if (package is! Package) throw const ValidationFailure();
    final result = await Purchases.purchase(PurchaseParams.package(package));
    _update(result.customerInfo);
  });

  @override
  Future<Result<bool>> restore() => _call(() async {
    _update(await Purchases.restorePurchases());
    return Premium.isActive;
  });
}
