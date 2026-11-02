import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/router/not_found_page.dart';
import 'package:__PROJECT_NAME__/features/home/presentation/home_page.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_page.dart';

/// Root navigator, used to show app-wide dialogs (e.g. the update dialog).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. Deep links are handled by go_router automatically.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  // Root navigator only. Tabs added later (StatefulShellBranch) need their
  // own `observers: Analytics.navigatorObservers` to be tracked.
  observers: [
    ...Monitoring.navigatorObservers,
    ...Analytics.navigatorObservers,
  ],
  // Every route has a `name`: it is the screen name in analytics ($screen)
  // and monitoring. Without one a nested route reports only its own path
  // piece (e.g. ':exerciseId'). Names are stable; never put ids in them.
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
