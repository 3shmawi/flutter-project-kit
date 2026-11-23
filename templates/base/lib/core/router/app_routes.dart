/// Every route path in one place. Each path is also a deep link:
/// `__SCHEME__://<path>` and, once the domain is verified,
/// `https://__DEEPLINK_DOMAIN__<path>`. Document new paths in
/// docs/deep_links.md.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  // @@if auth
  static const signIn = '/sign-in';
  static const account = '/account';
  static const newPassword = '/new-password';

  /// Paths that need a signed-in user; signed-out users are sent to
  /// [signIn] first (core/auth/auth_redirect.dart). Add yours here — e.g.
  /// [home] for an app that is only for signed-in users.
  static const signedInOnly = {account, newPassword};
  // @@endif
}
