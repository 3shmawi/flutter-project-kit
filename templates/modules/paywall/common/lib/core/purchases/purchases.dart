import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// How long a plan lasts, for its label on the paywall.
enum PlanPeriod { weekly, monthly, annual, lifetime, other }

/// One plan the user can buy, as the paywall shows it. [handle] is the
/// store SDK's own object, passed back to [PurchasesService.buy].
@immutable
class PaywallPlan {
  const PaywallPlan({
    required this.id,
    required this.period,
    required this.title,
    required this.price,
    this.handle,
  });

  final String id;
  final PlanPeriod period;

  /// The store's product title (used for [PlanPeriod.other]).
  final String title;

  /// Localized by the store, with currency: "EGP 99.99".
  final String price;
  final Object? handle;
}

/// Buying and restoring the premium entitlement. `core/purchases/
/// revenuecat_purchases.dart` implements it; tests use a fake.
abstract interface class PurchasesService {
  /// Configures the store SDK and fills [Premium.active].
  Future<void> start();

  /// The plans of the current offering, cheapest period first.
  Future<Result<List<PaywallPlan>>> plans();

  /// Buys [plan]. Success means the premium entitlement is active.
  Future<Result<void>> buy(PaywallPlan plan);

  /// Restores earlier purchases (required by Apple). Returns whether
  /// premium is active afterwards.
  Future<Result<bool>> restore();
}

/// App-wide premium state: screens and [PremiumGate] listen to [active].
abstract final class Premium {
  /// The entitlement id in RevenueCat (Project → Entitlements).
  static const entitlement = 'premium';

  static final ValueNotifier<bool> active = ValueNotifier(false);

  static PurchasesService service = const UnconfiguredPurchasesService();

  static bool get isActive => active.value;

  static Future<void> start(PurchasesService purchases) async {
    service = purchases;
    await purchases.start();
  }
}

/// Used while the env file has no RevenueCat key and in tests: nothing is
/// for sale and nobody is premium.
class UnconfiguredPurchasesService implements PurchasesService {
  const UnconfiguredPurchasesService();

  static const _failure = Failed<Never>(
    PurchaseFailure(PurchaseFailureReason.notConfigured),
  );

  @override
  Future<void> start() async {}

  @override
  Future<Result<List<PaywallPlan>>> plans() async => _failure;

  @override
  Future<Result<void>> buy(PaywallPlan plan) async => _failure;

  @override
  Future<Result<bool>> restore() async => _failure;
}
