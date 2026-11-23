import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__PROJECT_NAME__/features/paywall/presentation/paywall_view.dart';
import 'package:__PROJECT_NAME__/main.dart' as app;

import 'helpers/demo.dart';

/// Settings → Premium → the paywall. With RevenueCat keys in the env file
/// and a sandbox / license-tester account, the plans load from the store.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens the paywall from settings', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await skipOnboarding(tester);
    await beat(tester);

    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_premium')),
      200,
    );
    await beat(tester);
    await tester.tap(find.byKey(const Key('settings_premium')));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallView), findsOneWidget);
    await beat(tester, 1500);
  });
}
