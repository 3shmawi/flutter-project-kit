import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__PROJECT_NAME__/features/home/presentation/home_page.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';
import 'package:__PROJECT_NAME__/main.dart' as app;

import 'helpers/demo.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on home, opens settings and switches the language', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await skipOnboarding(tester);
    await beat(tester, 1500);

    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();
    await beat(tester);

    expect(find.byType(SettingsView), findsOneWidget);
    await beat(tester);

    // Language: the row opens a sheet; Arabic turns the app right-to-left.
    await tester.tap(find.byKey(const Key('settings_language')));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.tap(find.byKey(const Key('settings_choice_2')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(SettingsView))),
      TextDirection.rtl,
    );
    await beat(tester, 1500);
  });
}
