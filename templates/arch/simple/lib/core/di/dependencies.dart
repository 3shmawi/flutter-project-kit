import 'package:__PROJECT_NAME__/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root: long-lived objects created once at start-up.
/// Add new repositories / services here.
abstract final class Dependencies {
  static late final SettingsRepository settingsRepository;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SettingsRepository(prefs);
  }
}
