import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';

/// A [PurchasesService] for tests: sells [plans], records calls and returns
/// [nextFailure] once when set.
class FakePurchasesService implements PurchasesService {
  FakePurchasesService({
    this.available = const [
      PaywallPlan(
        id: 'monthly',
        period: PlanPeriod.monthly,
        title: 'Monthly',
        price: r'$4.99',
      ),
      PaywallPlan(
        id: 'annual',
        period: PlanPeriod.annual,
        title: 'Annual',
        price: r'$39.99',
      ),
    ],
    this.restorable = false,
  });

  final List<PaywallPlan> available;

  /// Whether restore finds an earlier purchase.
  final bool restorable;

  AppFailure? nextFailure;
  final calls = <String>[];

  Result<T> _result<T>(String call, T value) {
    calls.add(call);
    final failure = nextFailure;
    nextFailure = null;
    return failure == null ? Success(value) : Failed(failure);
  }

  @override
  Future<void> start() async {}

  @override
  Future<Result<List<PaywallPlan>>> plans() async => _result('plans', available);

  @override
  Future<Result<void>> buy(PaywallPlan plan) async {
    final result = _result<void>('buy:${plan.id}', null);
    if (result is Success<void>) Premium.active.value = true;
    return result;
  }

  @override
  Future<Result<bool>> restore() async {
    final result = _result('restore', restorable);
    if (restorable && result is Success<bool>) Premium.active.value = true;
    return result;
  }
}
