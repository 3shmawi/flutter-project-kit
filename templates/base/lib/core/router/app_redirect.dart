import 'package:flutter/foundation.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/auth_redirect.dart';
// @@endif
// @@if onboarding
import 'package:__PROJECT_NAME__/features/onboarding/data/onboarding.dart';
// @@endif

/// Every app-wide redirect, in order (first match wins). The router calls
/// this on each navigation and again when [redirectChanges] fires.
String? appRedirect(Uri uri) {
  // @@if onboarding
  final onboarding = onboardingRedirect(uri, seen: Onboarding.seen.value);
  if (onboarding != null) return onboarding;
  // @@endif
  // @@if auth
  return authRedirect(
    uri,
    signedIn: Auth.isSignedIn,
    passwordRecovery: Auth.passwordRecovery.value,
  );
  // @@else
  return null;
  // @@endif
}

/// What [appRedirect] depends on.
Listenable get redirectChanges => Listenable.merge([
  // @@if auth
  Auth.changes,
  // @@endif
  // @@if onboarding
  Onboarding.seen,
  // @@endif
]);
