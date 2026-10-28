import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Placeholder monitoring: logs errors to the console.
///
/// The rest of the app only talks to [Monitoring]. To add Sentry later:
/// `flutter pub add sentry_flutter`, then copy
/// `templates/monitoring/sentry/lib/core/monitoring/monitoring.dart` from the
/// kit over this file and set `SENTRY_DSN` in env/*.json.
abstract final class Monitoring {
  static Future<void> run(Future<Widget> Function() appBuilder) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(captureException(details.exception, details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(captureException(error, stackTrace));
      return true;
    };
    runApp(await appBuilder());
  }

  static Future<void> captureException(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    debugPrint('Monitoring: $error\n$stackTrace');
  }

  static Future<void> setUser(String? id) async {}

  static List<NavigatorObserver> get navigatorObservers => const [];
}
