import 'package:dio/dio.dart';

/// Refuses a request whose path has a `.` or `..` segment (also
/// percent-encoded), before it leaves the device. Path parameters come from
/// data — an item id like `../admin` must never reach another endpoint.
/// The plain Dio client encodes path parameters itself; Retrofit's
/// generated code doesn't, so this guard covers every API style.
///
/// It can't tell a `/` inside an id from a real path separator: when an id
/// may contain `/`, encode it (`Uri.encodeComponent`) before the call.
class PathGuardInterceptor extends Interceptor {
  static final _dotSegment = RegExp(
    r'(^|/)(\.|%2e){1,2}(/|\?|#|$)',
    caseSensitive: false,
  );

  static bool isSafe(String path) => !_dotSegment.hasMatch(path);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isSafe(options.path)) return handler.next(options);
    handler.reject(
      DioException(
        requestOptions: options,
        error: const FormatException('A path parameter may not be . or ..'),
      ),
    );
  }
}
