import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';

import '../../../helpers/pump_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'app',
      packageName: 'com.example.app',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  Widget view({
    AppSettings settings = const AppSettings(),
    ValueChanged<Locale?>? onLocaleChanged,
    ValueChanged<ThemeMode>? onThemeModeChanged,
    VoidCallback? onOpenPrivacy,
    VoidCallback? onOpenTerms,
    VoidCallback? onOpenLicenses,
  }) => SettingsView(
    settings: settings,
    onLocaleChanged: onLocaleChanged ?? (_) {},
    onThemeModeChanged: onThemeModeChanged ?? (_) {},
    onOpenPrivacy: onOpenPrivacy,
    onOpenTerms: onOpenTerms,
    onOpenLicenses: onOpenLicenses,
  );

  group(SettingsView, () {
    testWidgets('shows the app version and build number, left to right', (
      tester,
    ) async {
      await tester.pumpApp(view());
      await tester.pumpAndSettle();

      expect(find.text('1.2.3 (45)'), findsOneWidget);
      final value = tester.widget<Text>(
        find.byKey(const Key('settings_version')),
      );
      expect(value.textDirection, TextDirection.ltr);
    });

    testWidgets('rows show the current choices', (tester) async {
      await tester.pumpApp(
        view(
          settings: const AppSettings(
            locale: Locale('en'),
            themeMode: ThemeMode.dark,
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('settings_language')),
          matching: find.text(l10nEn.languageEnglish),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('settings_theme')),
          matching: find.text(l10nEn.settingsThemeDark),
        ),
        findsOneWidget,
      );
    });

    testWidgets('picks a language and a theme from the sheet', (
      tester,
    ) async {
      Locale? locale = const Locale('x');
      ThemeMode? themeMode;
      await tester.pumpApp(
        view(
          onLocaleChanged: (value) => locale = value,
          onThemeModeChanged: (value) => themeMode = value,
        ),
      );

      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_choice_2')));
      await tester.pumpAndSettle();
      expect(locale, const Locale('ar'));
      expect(find.byKey(const Key('settings_choice_2')), findsNothing);

      await tester.tap(find.byKey(const Key('settings_theme')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_choice_2')));
      await tester.pumpAndSettle();
      expect(themeMode, ThemeMode.dark);
    });

    testWidgets('closing the sheet changes nothing', (tester) async {
      var calls = 0;
      await tester.pumpApp(view(onLocaleChanged: (_) => calls++));

      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_choice_1')), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_choice_1')), findsNothing);
      expect(calls, 0);
    });

    testWidgets('the sheet marks the current choice', (tester) async {
      await tester.pumpApp(
        view(settings: const AppSettings(themeMode: ThemeMode.light)),
      );
      await tester.tap(find.byKey(const Key('settings_theme')));
      await tester.pumpAndSettle();

      bool selected(int i) => tester
          .getSemantics(find.byKey(Key('settings_choice_$i')))
          .flagsCollection
          .isSelected
          .toBoolOrNull()!;
      expect(selected(1), isTrue);
      expect(selected(2), isFalse);
    });

    testWidgets('opens the privacy policy, terms and licenses', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpApp(
        view(
          onOpenPrivacy: () => opened.add('privacy'),
          onOpenTerms: () => opened.add('terms'),
          onOpenLicenses: () => opened.add('licenses'),
        ),
      );

      // Module groups (account, premium, …) can push About below the fold.
      for (final label in [
        l10nEn.settingsPrivacy,
        l10nEn.settingsTerms,
        l10nEn.settingsLicenses,
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
      }
      expect(opened, ['privacy', 'terms', 'licenses']);
    });

    testWidgets('hides the About links without callbacks', (tester) async {
      await tester.pumpApp(view());
      expect(find.byKey(const Key('settings_privacy')), findsNothing);
      expect(find.byKey(const Key('settings_terms')), findsNothing);
      expect(find.byKey(const Key('settings_licenses')), findsNothing);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(
        view(onOpenPrivacy: () {}, onOpenTerms: () {}, onOpenLicenses: () {}),
      );
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });

    testWidgets('the choice sheet meets accessibility guidelines', (
      tester,
    ) async {
      await tester.pumpApp(view());
      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });
  });
}
