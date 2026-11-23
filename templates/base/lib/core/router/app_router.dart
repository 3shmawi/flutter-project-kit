import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
// @@if auth|onboarding
import 'package:__PROJECT_NAME__/core/router/app_redirect.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/router/not_found_page.dart';
// @@if auth
import 'package:__PROJECT_NAME__/features/auth/presentation/account_page.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/new_password_page.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/sign_in_page.dart';
// @@endif
import 'package:__PROJECT_NAME__/features/home/presentation/home_page.dart';
// @@if onboarding
import 'package:__PROJECT_NAME__/features/onboarding/presentation/onboarding_page.dart';
// @@endif
// @@if paywall
import 'package:__PROJECT_NAME__/features/paywall/presentation/paywall_page.dart';
// @@endif
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
  // @@if auth|onboarding
  // App-wide redirects (core/router/app_redirect.dart): first-launch
  // onboarding, signed-in-only paths.
  refreshListenable: redirectChanges,
  redirect: (context, state) => appRedirect(state.uri),
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
    // @@if onboarding
    GoRoute(
      path: AppRoutes.welcome,
      name: 'welcome',
      builder: (context, state) => const OnboardingPage(),
    ),
    // @@endif
    // @@if paywall
    GoRoute(
      path: AppRoutes.paywall,
      name: 'paywall',
      builder: (context, state) => const PaywallPage(),
    ),
    // @@endif
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
