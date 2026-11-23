import 'package:__PROJECT_NAME__/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/backend_auth.dart';
// @@endif

/// Composition root: long-lived objects created once at start-up.
/// Add new repositories / services here.
abstract final class Dependencies {
  static late final SettingsRepository settingsRepository;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SettingsRepository(prefs);
    // @@if auth
    await Auth.start(BackendAuthService());
    // @@endif
  }
}
