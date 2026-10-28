import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/__SETTINGS_REPO_PATH__';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_cubit.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repository;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = _MockSettingsRepository();
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  group(SettingsCubit, () {
    test('starts with the stored settings', () {
      when(() => repository.load()).thenReturn(
        const AppSettings(themeMode: ThemeMode.dark),
      );
      expect(
        SettingsCubit(repository).state,
        const AppSettings(themeMode: ThemeMode.dark),
      );
    });

    blocTest<SettingsCubit, AppSettings>(
      'setThemeMode emits and persists the new theme',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      expect: () => [const AppSettings(themeMode: ThemeMode.dark)],
      verify: (_) => verify(
        () => repository.save(const AppSettings(themeMode: ThemeMode.dark)),
      ).called(1),
    );

    blocTest<SettingsCubit, AppSettings>(
      'setLocale emits and persists the new language',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.setLocale(const Locale('ar')),
      expect: () => [const AppSettings(locale: Locale('ar'))],
    );

    blocTest<SettingsCubit, AppSettings>(
      'does nothing when the value did not change',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.setThemeMode(ThemeMode.system),
      expect: () => <AppSettings>[],
      verify: (_) => verifyNever(() => repository.save(any())),
    );
  });
}
