import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options for Cloud Messaging, from `env/<flavor>.json`
/// (`--dart-define-from-file`). This app keeps its data on Supabase; the
/// Firebase project is only there to send notifications. These values are
/// public identifiers, like the ones in `google-services.json`.
abstract final class FirebaseOptionsEnv {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  /// The options for this platform, or `null` while the env file is empty.
  static FirebaseOptions? get current => optionsFor(defaultTargetPlatform);

  @visibleForTesting
  static FirebaseOptions? optionsFor(TargetPlatform platform) {
    final (apiKey, appId) = switch (platform) {
      TargetPlatform.android => (androidApiKey, androidAppId),
      TargetPlatform.iOS => (iosApiKey, iosAppId),
      _ => ('', ''),
    };
    if (kIsWeb || projectId.isEmpty || apiKey.isEmpty || appId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }
}
