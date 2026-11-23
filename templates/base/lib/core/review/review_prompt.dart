import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/feature_flags/feature_flags.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When asking for a store rating is polite: after the user has come back
/// a few times over a few days, and not again for months. Apple shows the
/// system sheet at most 3 times a year anyway, and both stores may decide
/// not to show it; the app never knows.
@immutable
class ReviewPolicy {
  const ReviewPolicy({
    this.minLaunches = 5,
    this.minDaysInstalled = 3,
    this.minDaysBetween = 120,
  });

  final int minLaunches;
  final int minDaysInstalled;
  final int minDaysBetween;

  bool allows({
    required int launches,
    required DateTime? firstLaunch,
    required DateTime? lastAsked,
    required DateTime now,
  }) {
    if (launches < minLaunches || firstLaunch == null) return false;
    if (now.difference(firstLaunch).inDays < minDaysInstalled) return false;
    if (lastAsked != null && now.difference(lastAsked).inDays < minDaysBetween) {
      return false;
    }
    return true;
  }
}

/// The store's own rating sheet (`in_app_review`), shown at most once per
/// launch and only when [ReviewPolicy] allows it and the PostHog flag
/// `review_prompt` is on (off by default: turn it on once the app is
/// stable). Call [maybeAsk] right after a happy moment (a task finished,
/// a goal reached); the kit also tries once per launch when no update
/// dialog was shown (`core/update/app_update_listener.dart`).
abstract final class ReviewPrompt {
  static const _launchesKey = 'review.launches';
  static const _firstLaunchKey = 'review.first_launch';
  static const _lastAskedKey = 'review.last_asked';

  static SharedPreferences? _prefs;
  static bool _askedThisLaunch = false;

  @visibleForTesting
  static ReviewPolicy policy = const ReviewPolicy();

  /// Replaced in tests.
  @visibleForTesting
  static Future<void> Function() request = InAppReview.instance.requestReview;

  @visibleForTesting
  static Future<bool> Function() isAvailable = InAppReview.instance.isAvailable;

  @visibleForTesting
  static Future<bool> Function() flagEnabled = () =>
      FeatureFlags.isEnabled(Flags.reviewPrompt);

  /// Counts this launch (core/di/dependencies.dart).
  static Future<void> recordLaunch(SharedPreferences prefs, {DateTime? now}) async {
    _prefs = prefs;
    _askedThisLaunch = false;
    final time = now ?? DateTime.now();
    await prefs.setInt(_launchesKey, (prefs.getInt(_launchesKey) ?? 0) + 1);
    if (prefs.getInt(_firstLaunchKey) == null) {
      await prefs.setInt(_firstLaunchKey, time.millisecondsSinceEpoch);
    }
  }

  /// Shows the rating sheet when everything allows it. Returns whether it
  /// was requested (the store may still not show it).
  static Future<bool> maybeAsk({DateTime? now}) async {
    final prefs = _prefs;
    if (prefs == null || _askedThisLaunch) return false;
    final time = now ?? DateTime.now();
    DateTime? read(String key) {
      final ms = prefs.getInt(key);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    }

    final allowed = policy.allows(
      launches: prefs.getInt(_launchesKey) ?? 0,
      firstLaunch: read(_firstLaunchKey),
      lastAsked: read(_lastAskedKey),
      now: time,
    );
    if (!allowed) return false;
    try {
      if (!await flagEnabled() || !await isAvailable()) return false;
      _askedThisLaunch = true;
      await prefs.setInt(_lastAskedKey, time.millisecondsSinceEpoch);
      await request();
      unawaited(Analytics.capture('review_prompt_requested'));
      return true;
    } on Exception {
      // A rating sheet is never worth an error.
      return false;
    }
  }
}
