import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// @@if backend_firebase
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:__PROJECT_NAME__/core/push/push.dart';
// @@if !backend_firebase
import 'package:__PROJECT_NAME__/core/push/firebase_options_env.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/router/app_router.dart';
import 'package:__PROJECT_NAME__/core/ui/app_message.dart';

/// [PushService] on Firebase Cloud Messaging (FCM sends through APNs on
/// iOS). Topic-based: every user who allowed notifications is subscribed
/// to the update topic in their language. To push to one user, save the
/// device's FCM registration token on the backend (docs/features/push.md).
class FirebasePushService implements PushService {
  FirebasePushService();

  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _foreground;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<bool> _ensureFirebase() async {
    // @@if backend_firebase
    // Backend.init() already started Firebase with the env file's options.
    return Backend.isConfigured;
    // @@else
    // This app's data isn't on Firebase: Firebase is only used for FCM, with
    // the FIREBASE_* values from the env file.
    final options = FirebaseOptionsEnv.current;
    if (options == null) return false;
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
    return true;
    // @@endif
  }

  @override
  Future<void> start() async {
    try {
      if (!await _ensureFirebase()) return;
      final settings = await _messaging.getNotificationSettings();
      Push.permission.value = _permission(settings.authorizationStatus);
      if (Push.permission.value == PushPermission.granted) {
        await _subscribe();
      }
      _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(_open);
      _foreground ??= FirebaseMessaging.onMessage.listen(_showInApp);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } on FirebaseException catch (error, stackTrace) {
      unawaited(Monitoring.captureException(error, stackTrace));
    }
  }

  Future<void> stop() async {
    await _opened?.cancel();
    await _foreground?.cancel();
    _opened = _foreground = null;
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!await _ensureFirebase()) return PushPermission.unsupported;
    final settings = await _messaging.requestPermission();
    final permission = _permission(settings.authorizationStatus);
    Push.permission.value = permission;
    if (permission == PushPermission.granted) await _subscribe();
    return permission;
  }

  static PushPermission _permission(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  Future<void> _subscribe() async {
    final topic = Push.updatesTopic(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    for (final other in ['updates_en', 'updates_ar']) {
      if (other != topic) await _messaging.unsubscribeFromTopic(other);
    }
    await _messaging.subscribeToTopic(topic);
  }

  /// A tapped notification opens its `route` (validated, inside the app).
  static void _open(RemoteMessage message) {
    final route = Push.routeOf(message.data);
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => appRouter.go(route));
  }

  /// While the app is open the system shows nothing: show a message.
  static void _showInApp(RemoteMessage message) {
    final notification = message.notification;
    final context = rootNavigatorKey.currentContext;
    if (notification == null || context == null) return;
    final text = [
      notification.title,
      notification.body,
    ].whereType<String>().join('\n');
    if (text.isEmpty) return;
    showAppMessage(context, text);
  }
}
