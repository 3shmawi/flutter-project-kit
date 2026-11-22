/// Compile-time configuration, read from `env/<flavor>.json` via
/// `--dart-define-from-file`. Never put real secrets here: anything compiled
/// into the app can be extracted. Server-side secrets stay on the backend.
/// Backend values (Supabase / Firebase) are read in `core/backend/backend.dart`.
abstract final class Env {
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const clarityProjectId = String.fromEnvironment('CLARITY_PROJECT_ID');
}
