import 'dart:async';

import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/__SETTINGS_REPO_PATH__';

/// Holds the current [AppSettings]; changes are applied immediately and
/// persisted in the background.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository) : _settings = _repository.load();

  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  void setLocale(Locale? locale) =>
      _update(_settings.copyWith(locale: () => locale));

  void setThemeMode(ThemeMode themeMode) =>
      _update(_settings.copyWith(themeMode: themeMode));

  void _update(AppSettings next) {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    unawaited(_repository.save(next));
  }
}
