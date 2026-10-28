import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/__SETTINGS_REPO_PATH__';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_controller.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repository;
  late SettingsController controller;
  late int notifications;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = _MockSettingsRepository();
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
    notifications = 0;
    controller = SettingsController(repository)
      ..addListener(() => notifications++);
    addTearDown(controller.dispose);
  });

  group(SettingsController, () {
    test('setThemeMode notifies and persists', () {
      controller.setThemeMode(ThemeMode.dark);

      expect(controller.settings.themeMode, ThemeMode.dark);
      expect(notifications, 1);
      verify(
        () => repository.save(const AppSettings(themeMode: ThemeMode.dark)),
      ).called(1);
    });

    test('setLocale notifies with the new language', () {
      controller.setLocale(const Locale('ar'));

      expect(controller.settings.locale, const Locale('ar'));
      expect(notifications, 1);
    });

    test('does nothing when the value did not change', () {
      controller.setThemeMode(ThemeMode.system);

      expect(notifications, 0);
      verifyNever(() => repository.save(any()));
    });
  });
}
