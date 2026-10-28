import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
import 'package:__PROJECT_NAME__/core/di/dependencies.dart';
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:__PROJECT_NAME__/core/theme/app_fonts.dart';

/// Starts monitoring first, then initialises every core service and runs
/// the app. Anything that fails during start-up is reported.
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFonts.registerLicenses();
  await Monitoring.run(() async {
    await Backend.init();
    await Analytics.init();
    await Dependencies.init();
    return builder();
  });
}
