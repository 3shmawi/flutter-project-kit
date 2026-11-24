import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/core/config/app_flavor.dart';
import 'package:__PROJECT_NAME__/core/config/env.dart';
import 'package:__PROJECT_NAME__/core/device/test_device.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash, error and performance monitoring — backed by Sentry.
///
/// The rest of the app only talks to [Monitoring], so switching or adding a
/// provider means changing this one file. Disabled until `SENTRY_DSN` is set.
abstract final class Monitoring {
  /// Off without a DSN, and on Google's test devices (core/device): their
  /// emulators would send most crashes and 504s (docs/security.md).
  static bool get _enabled =>
      Env.sentryDsn.isNotEmpty && !TestDevice.isTestLab;

  /// Builds the app inside Sentry's zone so start-up errors are captured.
  static Future<void> run(Future<Widget> Function() appBuilder) async {
    if (!_enabled) {
      runApp(await appBuilder());
      return;
    }
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = Env.sentryDsn
          ..environment = AppFlavor.current.name
          ..tracesSampleRate = AppFlavor.current.isProd ? 0.2 : 1.0
          ..sendDefaultPii = false
          // No network, or a server that is down for a moment, is not a
          // bug: also drop the ones Sentry catches by itself (isOutage).
          ..beforeSend = dropOutages;
      },
      appRunner: () async => runApp(SentryWidget(child: await appBuilder())),
    );
  }

  /// Sentry's `beforeSend`: drops events whose error is an outage.
  @visibleForTesting
  static SentryEvent? dropOutages(SentryEvent event, Hint hint) {
    final Object? error = event.throwable;
    return error != null && isOutage(error) ? null : event;
  }

  /// Reports an error you caught and handled. No network, a timeout, or a
  /// server that answered 502/503/504 is not reported: it is not a bug, the
  /// app already shows offline or retries.
  static Future<void> captureException(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    if (isOutage(error)) return;
    if (!_enabled) {
      debugPrint('Monitoring: $error\n$stackTrace');
      return;
    }
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Ties errors to the signed-in user (call with `null` on sign-out).
  static Future<void> setUser(String? id) async {
    if (!_enabled) return;
    await Sentry.configureScope(
      (scope) => scope.setUser(id == null ? null : SentryUser(id: id)),
    );
  }

  static List<NavigatorObserver> get navigatorObservers =>
      _enabled ? [SentryNavigatorObserver()] : const [];
}
