import 'package:__PROJECT_NAME__/core/router/app_routes.dart';

/// The router's redirect for sign-in (pure, so it is unit-tested):
/// - signed out on a signed-in-only path → the sign-in screen, remembering
///   where the user was going (`?from=`);
/// - signed in on the sign-in screen → back to `from` (inside the app only);
/// - after a password-reset link → the new-password screen.
/// Returns `null` to stay.
String? authRedirect(
  Uri uri, {
  required bool signedIn,
  bool passwordRecovery = false,
}) {
  final path = uri.path;
  if (signedIn && passwordRecovery && path != AppRoutes.newPassword) {
    return AppRoutes.newPassword;
  }
  if (!signedIn && isSignedInOnly(path)) {
    return Uri(
      path: AppRoutes.signIn,
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  if (signedIn && path == AppRoutes.signIn) {
    return safeReturnPath(uri.queryParameters['from']);
  }
  return null;
}

/// Whether [path] (or a parent of it) is in [AppRoutes.signedInOnly].
bool isSignedInOnly(String path) => AppRoutes.signedInOnly.any(
  (p) => path == p || path.startsWith('$p/'),
);

/// [from] when it is a path inside the app; the home screen otherwise.
/// `?from=` comes from a URL anyone can craft: never follow it to another
/// host (`//evil.example`, `https://…`) or back to the sign-in screen.
String safeReturnPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return AppRoutes.home;
  }
  if (from.contains(r'\')) return AppRoutes.home;
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return AppRoutes.home;
  if (uri.path == AppRoutes.signIn) return AppRoutes.home;
  return from;
}

/// Basic checks before anything reaches the backend (it checks again).
abstract final class AuthInput {
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;
  static const emailMaxLength = 254;

  // Loose on purpose (the backend checks the address for real), but no
  // spaces, quotes or angle brackets.
  static final _email = RegExp(
    r'''^[^\s@<>"'()]+@[^\s@<>"'()]+\.[^\s@<>"'()]+$''',
  );

  static bool isEmail(String value) {
    final email = value.trim();
    return email.length <= emailMaxLength && _email.hasMatch(email);
  }

  static bool isPassword(String value) =>
      value.length >= passwordMinLength && value.length <= passwordMaxLength;
}
