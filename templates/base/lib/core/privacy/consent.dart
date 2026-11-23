import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's answer to "may we collect usage data?".
enum ConsentChoice {
  /// Not asked yet: analytics stay off.
  unknown,
  granted,
  denied,
}

/// Consent for product analytics (PostHog) and session replays (Clarity).
/// Opt-in: nothing is collected until the user allows it — the first-launch
/// sheet (`consent_sheet.dart`) asks, Settings → Privacy changes it any
/// time. Crash reports (Sentry) don't depend on it: they keep the app
/// working and hold no usage data (website/privacy.html).
abstract final class Consent {
  static const _key = 'consent.analytics';

  static final ValueNotifier<ConsentChoice> analytics = ValueNotifier(
    ConsentChoice.unknown,
  );

  static bool get analyticsAllowed => analytics.value == ConsentChoice.granted;

  static SharedPreferences? _prefs;

  /// Reads the saved answer (bootstrap.dart, before analytics start).
  static Future<void> load([SharedPreferences? prefs]) async {
    final store = _prefs = prefs ?? await SharedPreferences.getInstance();
    analytics.value = ConsentChoice.values.asNameMap()[store.getString(_key)] ??
        ConsentChoice.unknown;
  }

  /// Saves the answer; listeners (analytics, monitoring) apply it at once.
  static Future<void> set(ConsentChoice choice) async {
    analytics.value = choice;
    await _prefs?.setString(_key, choice.name);
  }
}
