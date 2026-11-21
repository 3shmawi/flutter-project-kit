import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase access (Cloud Firestore). Skipped gracefully when the env file
/// has no values yet.
///
/// The options come from `env/<flavor>.json` (`--dart-define-from-file`),
/// not from `google-services.json` / `GoogleService-Info.plist` or
/// `firebase_options.dart`, so every flavor can point at its own Firebase
/// project without native files. These values are public by design: what a
/// client may read or write is decided by `firebase/firestore.rules`.
///
/// Feature data sources use [firestore]; core code only uses the
/// backend-neutral calls below, so it stays the same whichever backend the
/// project was created with.
abstract final class Backend {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static const name = 'Firebase';

  /// The options for this platform, or `null` while the env file is empty.
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
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }

  static bool get isConfigured => optionsFor(defaultTargetPlatform) != null;

  static Future<void> init() async {
    final options = optionsFor(defaultTargetPlatform);
    if (options == null) return;
    await Firebase.initializeApp(options: options);
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// The `app_versions/<platform>` document (`android` / `ios`), or `null`.
  static Future<Map<String, dynamic>?> appVersion(String platform) async {
    final doc = await firestore.collection('app_versions').doc(platform).get();
    return doc.data();
  }
}
