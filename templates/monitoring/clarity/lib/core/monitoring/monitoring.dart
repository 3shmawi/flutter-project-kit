import 'dart:async';
import 'dart:ui';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/config/app_flavor.dart';
import 'package:__PROJECT_NAME__/core/config/env.dart';

/// Session recordings and heatmaps — backed by Microsoft Clarity.
/// Clarity has no error API, so errors are sent to analytics as `app_error`.
///
/// The rest of the app only talks to [Monitoring], so switching or adding a
/// provider means changing this one file. Disabled until
/// `CLARITY_PROJECT_ID` is set.
abstract final class Monitoring {
  static bool get _enabled => Env.clarityProjectId.isNotEmpty;

  static Future<void> run(Future<Widget> Function() appBuilder) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(captureException(details.exception, details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(captureException(error, stackTrace));
      return true;
    };

    final app = await appBuilder();
    if (!_enabled) {
      runApp(app);
      return;
    }
    runApp(
      ClarityWidget(
        app: app,
        clarityConfig: ClarityConfig(
          projectId: Env.clarityProjectId,
          logLevel: AppFlavor.current.isProd ? LogLevel.None : LogLevel.Info,
        ),
      ),
    );
  }

  static Future<void> captureException(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    debugPrint('Monitoring: $error\n$stackTrace');
    await Analytics.capture('app_error', {
      'error': error.toString(),
      'type': error.runtimeType.toString(),
    });
  }

  static Future<void> setUser(String? id) async {}

  static List<NavigatorObserver> get navigatorObservers => const [];
}
