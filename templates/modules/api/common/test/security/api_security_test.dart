import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';
import 'package:__PROJECT_NAME__/core/api/path_guard_interceptor.dart';

/// The REST API module's guarantees (docs/features/api.md → Security).
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('no request/response logging that could print tokens', () {
    final logging = RegExp(
      r'LogInterceptor|PrettyDioLogger|requestHeader:\s*true|logPrint',
    );
    final offenders = [
      for (final file in dartFiles('lib'))
        if (logging.hasMatch(file.readAsStringSync())) file.path,
    ];
    expect(offenders, isEmpty);
  });

  test('only the auth interceptor touches the Authorization header', () {
    final offenders = [
      for (final file in dartFiles('lib'))
        if (!file.path.endsWith('auth_interceptor.dart') &&
            !file.path.contains('${Platform.pathSeparator}gen${Platform.pathSeparator}') &&
            RegExp('[\'"]Authorization[\'"]').hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });

  test('API_BASE_URL is https (http only to localhost, never in prod)', () {
    for (final file in Directory('env').listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final url = json['API_BASE_URL'] as String? ?? '';
      if (url.isEmpty) continue;
      final prod = file.path.endsWith('prod.json');
      expect(
        ApiConfig.checkBaseUrl(url, release: prod),
        isNull,
        reason: '${file.path}: API_BASE_URL',
      );
    }
  });

  test('dot segments never leave the device (any API style)', () {
    for (final path in [
      '/items/..',
      '/items/../admin',
      '/items/./x',
      '/items/%2e%2e/admin',
      '/items/%2E%2E',
      '..',
    ]) {
      expect(PathGuardInterceptor.isSafe(path), isFalse, reason: path);
    }
    for (final path in ['/items', '/items/42', '/items/a.b', '/items/...x']) {
      expect(PathGuardInterceptor.isSafe(path), isTrue, reason: path);
    }
    final interceptors = ApiClient.createDio(
      baseUrl: 'https://api.example.com',
    ).interceptors;
    expect(interceptors.whereType<PathGuardInterceptor>(), hasLength(1));
  });

  test('the client never follows redirects', () {
    final dio = ApiClient.createDio(baseUrl: 'https://api.example.com');
    expect(dio.options.followRedirects, isFalse);
    expect(dio.options.maxRedirects, 0);
  });
}
