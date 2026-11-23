import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/auth_redirect.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/router/not_found_page.dart';
// @@if auth
import 'package:__PROJECT_NAME__/features/auth/presentation/account_page.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/new_password_page.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/sign_in_page.dart';
// @@endif
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
  // @@if auth
  // Signed-out users can't open signed-in-only paths (AppRoutes.signedInOnly).
  refreshListenable: Auth.changes,
  redirect: (context, state) => authRedirect(
    state.uri,
    signedIn: Auth.isSignedIn,
    passwordRecovery: Auth.passwordRecovery.value,
  ),
  // @@endif
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
    // @@if auth
    GoRoute(
      path: AppRoutes.signIn,
      name: 'sign_in',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: AppRoutes.account,
      name: 'account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: AppRoutes.newPassword,
      name: 'new_password',
      builder: (context, state) => const NewPasswordPage(),
    ),
    // @@endif
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
