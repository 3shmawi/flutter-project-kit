import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase access. Skipped gracefully when the env file has no values yet.
///
/// Feature data sources use [client] (tables, auth, storage, functions);
/// core code only uses the backend-neutral calls below, so it stays the same
/// whichever backend the project was created with.
abstract final class Backend {
  /// `env/<flavor>.json` → `--dart-define-from-file`. Publishable values
  /// only: the anon/publishable key is safe in the app *because* every table
  /// has RLS.
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const name = 'Supabase';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// The `app_versions` row for [platform] (`android` / `ios`), or `null`.
  static Future<Map<String, dynamic>?> appVersion(String platform) =>
      client.from('app_versions').select().eq('platform', platform).maybeSingle();
}
