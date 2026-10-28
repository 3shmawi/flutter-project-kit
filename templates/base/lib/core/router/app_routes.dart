/// Every route path in one place. Each path is also a deep link:
/// `__SCHEME__://<path>` and, once the domain is verified,
/// `https://__DEEPLINK_DOMAIN__<path>`. Document new paths in
/// docs/deep_links.md.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
}
