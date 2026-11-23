import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__PROJECT_NAME__/main.dart' as app;

import 'helpers/demo.dart';

/// Settings shows the notification state. The system prompt itself can't
/// be tapped from a Flutter test: grant it on the simulator first
/// (`xcrun simctl privacy booted grant notifications <bundle id>`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings shows the notifications row', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await skipOnboarding(tester);
    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_notifications')),
      200,
    );
    expect(find.byKey(const Key('settings_notifications')), findsOneWidget);
    await beat(tester, 1500);
  });
}
