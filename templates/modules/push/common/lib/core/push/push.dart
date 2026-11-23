import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Whether the app may show notifications.
enum PushPermission {
  granted,
  denied,

  /// Never asked yet: the Settings row asks.
  notDetermined,

  /// Push isn't set up in this env file (or the platform has none).
  unsupported,
}

/// Push notifications, provider-neutral. `core/push/firebase_push.dart`
/// implements it with Firebase Cloud Messaging.
abstract interface class PushService {
  /// Reads the permission, subscribes to topics when allowed and handles
  /// taps (cold start included).
  Future<void> start();

  /// Shows the system prompt (iOS, Android 13+). Ask in context — from
  /// Settings or after the user did something worth being notified about —
  /// never on the first launch.
  Future<PushPermission> requestPermission();
}

abstract final class Push {
  static final ValueNotifier<PushPermission> permission = ValueNotifier(
    PushPermission.unsupported,
  );

  static PushService service = const UnconfiguredPushService();

  static Future<void> start(PushService push) async {
    service = push;
    await push.start();
  }

  /// Every user gets app-update news in their language: Actions → Announce
  /// update → *push* sends to `updates_en` and `updates_ar`.
  static String updatesTopic(Locale locale) =>
      locale.languageCode == 'ar' ? 'updates_ar' : 'updates_en';

  /// The screen a notification opens: `data.route`, only when it is a path
  /// inside the app (`/settings`). Anything else — another host, a scheme,
  /// `//evil.example` — opens nothing. Notifications are untrusted input
  /// like deep links.
  static String? routeOf(Map<String, Object?> data) {
    final route = data['route'];
    if (route is! String || route.isEmpty || route.length > 512) return null;
    if (!route.startsWith('/') || route.startsWith('//')) return null;
    if (route.contains(r'\')) return null;
    final uri = Uri.tryParse(route);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    return route;
  }
}

class UnconfiguredPushService implements PushService {
  const UnconfiguredPushService();

  @override
  Future<void> start() async {}

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unsupported;
}
