import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this install has seen the welcome screens. Stored on the device.
abstract final class Onboarding {
  static const _key = 'onboarding.done';

  /// `true` until [load] reads the real value, so tests and screens that
  /// don't care never get redirected.
  static final ValueNotifier<bool> seen = ValueNotifier(true);

  static SharedPreferences? _prefs;

  /// Reads the saved value (core/di/dependencies.dart).
  static void load(SharedPreferences prefs) {
    _prefs = prefs;
    seen.value = prefs.getBool(_key) ?? false;
  }

  static Future<void> complete() async {
    seen.value = true;
    await _prefs?.setBool(_key, true);
  }
}

/// A new install opening the app normally (the home screen) sees the
/// welcome screens first. Deep links into other screens go straight there.
String? onboardingRedirect(Uri uri, {required bool seen}) {
  if (seen) return null;
  return uri.path == AppRoutes.home ? AppRoutes.welcome : null;
}
