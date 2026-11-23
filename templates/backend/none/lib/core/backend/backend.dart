// @@if api
import 'package:dio/dio.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';

/// No Supabase / Firebase: the app's data lives behind your REST API
/// (`lib/core/api/`, contract in `api/openapi.yaml`). Feature data sources
/// call `ApiClient.api`; core code only uses the backend-neutral calls
/// below, so it stays the same whichever backend the project uses.
abstract final class Backend {
  static const name = 'REST API';

  static bool get isConfigured => ApiConfig.isConfigured;

  static Future<void> init() async {}

  /// The version-update gate: `GET /app-versions/{platform}` (`android` /
  /// `ios`) on your API, or `null` when it has no record.
  static Future<Map<String, dynamic>?> appVersion(String platform) async {
    try {
      final version = await ApiClient.api.app.getAppVersion(
        platform: platform,
      );
      return version.toJson();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
// @@else
/// No backend: the app keeps its data on the device. Core code only uses
/// the backend-neutral calls below; add Supabase, Firebase or your REST API
/// (`scripts/add_module.sh api`) when the app needs a server.
abstract final class Backend {
  static const name = 'none';

  /// Nothing to configure: the version-update gate stays off.
  static bool get isConfigured => false;

  static Future<void> init() async {}

  static Future<Map<String, dynamic>?> appVersion(String platform) async =>
      null;
}
// @@endif
