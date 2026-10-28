import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/__SETTINGS_REPO_PATH__';

/// Holds the current [AppSettings]; changes are applied immediately and
/// persisted in the background.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  void setLocale(Locale? locale) => _update(state.copyWith(locale: () => locale));

  void setThemeMode(ThemeMode themeMode) =>
      _update(state.copyWith(themeMode: themeMode));

  void _update(AppSettings next) {
    if (next == state) return;
    emit(next);
    unawaited(_repository.save(next));
  }
}
