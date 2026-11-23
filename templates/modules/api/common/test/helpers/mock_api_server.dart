import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real HTTP server on 127.0.0.1 for API tests: answers from [routes]
/// and records every request. Plain `http://` to localhost is allowed in
/// debug builds only (ApiConfig.checkBaseUrl).
///
/// Use it from `test()`, not `testWidgets()`: widget tests replace the
/// HTTP client with one that answers 400.
class MockApiServer {
  late final HttpServer _server;

  /// `'GET /items'` → the response. Unknown routes answer 404.
  final Map<String, MockResponse Function(RecordedRequest request)> routes =
      {};
  final List<RecordedRequest> requests = [];

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) => unawaited(_handle(request)));
  }

  Future<void> close() => _server.close(force: true);

  void on(String route, MockResponse Function(RecordedRequest request) answer) =>
      routes[route] = answer;

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final recorded = RecordedRequest(
      method: request.method,
      path: request.uri.path,
      query: request.uri.queryParameters,
      authorization: request.headers.value(HttpHeaders.authorizationHeader),
      body: body.isEmpty ? null : jsonDecode(body),
    );
    requests.add(recorded);
    final answer = routes['${request.method} ${request.uri.path}'];
    final response = answer?.call(recorded) ?? const MockResponse(404);
    request.response.statusCode = response.status;
    response.headers.forEach(request.response.headers.set);
    if (response.body != null) {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response.body));
    }
    await request.response.close();
  }
}

class MockResponse {
  const MockResponse(this.status, [this.body, this.headers = const {}]);

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.authorization,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final String? authorization;
  final Object? body;
}
