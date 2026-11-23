import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/features/paywall/presentation/paywall_page.dart';

import '../../../helpers/fake_purchases_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakePurchasesService store;

  setUp(() {
    store = FakePurchasesService();
    Premium.service = store;
    Premium.active.value = false;
  });
  tearDown(() {
    Premium.service = const UnconfiguredPurchasesService();
    Premium.active.value = false;
  });

  group(PaywallPage, () {
    testWidgets('lists the plans with their store prices', (tester) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.paywallPlanMonthly), findsOneWidget);
      expect(find.text(l10nEn.paywallPlanAnnual), findsOneWidget);
      expect(find.text(r'$4.99'), findsOneWidget);
      expect(find.text(r'$39.99'), findsOneWidget);
      // Apple 3.1.2: renewal terms and Restore on the paywall.
      expect(find.text(l10nEn.paywallRenewalNote), findsOneWidget);
      expect(find.byKey(const Key('paywall_restore')), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });

    testWidgets('buys the yearly plan by default and unlocks premium', (
      tester,
    ) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paywall_continue')));
      await tester.pumpAndSettle();

      expect(store.calls, ['plans', 'buy:annual']);
      expect(Premium.isActive, isTrue);
      expect(find.text(l10nEn.paywallActive), findsOneWidget);
    });

    testWidgets('buys the plan the user picked', (tester) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paywall_plan_monthly')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paywall_continue')));
      await tester.pumpAndSettle();

      expect(store.calls.last, 'buy:monthly');
    });

    testWidgets('a closed store sheet shows nothing', (tester) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      store.nextFailure = const PurchaseFailure(
        PurchaseFailureReason.cancelled,
      );
      await tester.tap(find.byKey(const Key('paywall_continue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paywall_message')), findsNothing);
      expect(Premium.isActive, isFalse);
    });

    testWidgets('a pending purchase says it will unlock later', (
      tester,
    ) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      store.nextFailure = const PurchaseFailure(PurchaseFailureReason.pending);
      await tester.tap(find.byKey(const Key('paywall_continue')));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.purchaseErrorPending), findsOneWidget);
    });

    testWidgets('restore says when nothing was found', (tester) async {
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paywall_restore')));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.paywallNothingToRestore), findsOneWidget);
    });

    testWidgets('loading failures show Try again', (tester) async {
      store.nextFailure = const NetworkFailure();
      await tester.pumpApp(const PaywallPage());
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.errorNetwork), findsOneWidget);
      await tester.tap(find.text(l10nEn.retry));
      await tester.pumpAndSettle();
      expect(find.text(r'$4.99'), findsOneWidget);
    });

    testWidgets('works right to left in Arabic', (tester) async {
      await tester.pumpApp(const PaywallPage(), locale: const Locale('ar'));
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(ListView))),
        TextDirection.rtl,
      );
    });
  });
}
