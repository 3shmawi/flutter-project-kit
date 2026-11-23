import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/features/items/data/items_repository.dart';

import '../../../helpers/mock_api_server.dart';

void main() {
  late MockApiServer server;
  late ItemsRepository repository;

  Map<String, Object?> item(String id, String title) => {
    'id': id,
    'title': title,
    'done': false,
    'created_at': '2026-11-23T10:00:00Z',
  };

  setUp(() async {
    server = MockApiServer();
    await server.start();
    repository = ItemsRepository(
      Api(ApiClient.createDio(baseUrl: server.baseUrl)),
    );
  });

  tearDown(() => server.close());

  test('lists items', () async {
    server.on(
      'GET /items',
      (_) => MockResponse(200, [item('1', 'Milk'), item('2', 'Bread')]),
    );
    final result = await repository.items(limit: 2);
    final items = (result as Success<List<Item>>).value;
    expect(items.map((i) => i.title), ['Milk', 'Bread']);
    expect(items.first.createdAt, DateTime.utc(2026, 11, 23, 10));
    expect(server.requests.single.query, {'limit': '2'});
  });

  test('clamps the page size', () async {
    server.on('GET /items', (_) => const MockResponse(200, <Object>[]));
    await repository.items(limit: 100000);
    expect(server.requests.single.query, {'limit': '100'});
  });

  test('adds an item with a trimmed title, once', () async {
    server.on(
      'POST /items',
      (request) => MockResponse(201, {
        ...item('3', (request.body! as Map)['title'] as String),
      }),
    );
    final result = await repository.add('  Eggs  ');
    expect((result as Success<Item>).value.title, 'Eggs');
    expect(server.requests.single.body, {'title': 'Eggs'});
  });

  test('refuses empty or too long titles without calling the API', () async {
    for (final title in ['', '   ', 'x' * 201]) {
      final result = await repository.add(title);
      expect((result as Failed).failure, isA<ValidationFailure>());
    }
    expect(server.requests, isEmpty);
  });

  test('sends hostile text as data, not as a request', () async {
    const hostile = "'; DROP TABLE items; -- <script>alert(1)</script> {{x}}";
    server.on(
      'POST /items',
      (request) =>
          MockResponse(201, item('4', (request.body! as Map)['title'] as String)),
    );
    final result = await repository.add(hostile);
    expect((result as Success<Item>).value.title, hostile);
    expect(server.requests.single.path, '/items');
  });

  test('a path id cannot escape its segment', () async {
    server.on('DELETE /admin', (_) => const MockResponse(204));
    for (final id in ['..', '.', '../admin', '%2e%2e', '%2E%2E%2Fadmin']) {
      final result = await repository.remove(id);
      expect(result, isA<Failed<void>>(), reason: id);
    }
    expect(server.requests.where((r) => r.path == '/admin'), isEmpty);
  });

  test('a response that breaks the contract is a failure, not a crash', () async {
    server.on('GET /items', (_) => const MockResponse(200, {'oops': true}));
    final result = await repository.items();
    expect(result, isA<Failed<List<Item>>>());
  });
}
