import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';

/// The signed-in session, as the device keeps it.
@immutable
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.email,
  });

  factory StoredSession.fromApi(Session session) => StoredSession(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    userId: session.user.id,
    email: session.user.email,
  );

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String? email;

  /// Never print the tokens (logs, crash reports).
  @override
  String toString() => 'StoredSession(user: $userId)';
}

/// The API session in the Keychain (iOS, this device only — not in
/// backups or on other devices) / Android Keystore-encrypted storage.
/// Never in SharedPreferences, never in logs.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _key = 'api_session';

  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return StoredSession(
        accessToken: json['access_token']! as String,
        refreshToken: json['refresh_token']! as String,
        userId: json['user_id']! as String,
        email: json['email'] as String?,
      );
    } on Object {
      // Unreadable (format changed): start signed out.
      await clear();
      return null;
    }
  }

  Future<StoredSession> save(Session session) async {
    final stored = StoredSession.fromApi(session);
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'access_token': stored.accessToken,
        'refresh_token': stored.refreshToken,
        'user_id': stored.userId,
        'email': stored.email,
      }),
    );
    return stored;
  }

  Future<void> clear() => _storage.delete(key: _key);
}
