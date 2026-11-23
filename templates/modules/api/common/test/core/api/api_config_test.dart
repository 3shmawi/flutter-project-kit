import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';

void main() {
  group('ApiConfig.checkBaseUrl', () {
    test('accepts https', () {
      expect(ApiConfig.checkBaseUrl('https://api.example.com/v1'), isNull);
      expect(
        ApiConfig.checkBaseUrl('https://api.example.com', release: true),
        isNull,
      );
    });

    test('refuses plain http to a real host, even in debug', () {
      expect(ApiConfig.checkBaseUrl('http://api.example.com'), isNotNull);
    });

    test('allows http to a local dev server in debug only', () {
      for (final url in [
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://10.0.2.2:8080',
      ]) {
        expect(ApiConfig.checkBaseUrl(url, release: false), isNull, reason: url);
        expect(ApiConfig.checkBaseUrl(url, release: true), isNotNull, reason: url);
      }
    });

    test('refuses empty, broken and hostile values', () {
      for (final url in [
        '',
        'api.example.com',
        'ftp://api.example.com',
        'https://user:secret@api.example.com',
        'https://api.example.com/?token=abc',
        'https://api.example.com/#x',
        'javascript:alert(1)',
        'https://',
        'http://localhost.evil.com',
      ]) {
        expect(ApiConfig.checkBaseUrl(url), isNotNull, reason: url);
      }
    });
  });
}
