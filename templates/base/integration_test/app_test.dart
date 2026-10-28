import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__PROJECT_NAME__/features/home/presentation/home_page.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';
import 'package:__PROJECT_NAME__/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on home and opens settings', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsView), findsOneWidget);
  });
}
