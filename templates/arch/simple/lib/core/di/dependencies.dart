import 'package:__PROJECT_NAME__/features/settings/data/settings_repository.dart';
import 'package:__PROJECT_NAME__/core/review/review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
// @@if di_get_it
import 'package:get_it/get_it.dart';
// @@endif
// @@if api
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
// @@if di_get_it
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/api/backend_api_tokens.dart';
// @@if di_get_it
import 'package:__PROJECT_NAME__/features/items/data/items_repository.dart';
// @@endif
// @@endif
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/backend_auth.dart';
// @@endif
// @@if paywall
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/purchases/revenuecat_purchases.dart';
// @@endif
// @@if onboarding
import 'package:__PROJECT_NAME__/features/onboarding/data/onboarding.dart';
// @@endif
// @@if push
import 'package:__PROJECT_NAME__/core/push/firebase_push.dart';
import 'package:__PROJECT_NAME__/core/push/push.dart';
// @@endif

// @@if di_get_it
/// The app's service locator. Read registered objects with `getIt<T>()` in
/// pages, state holders' factories and other composition code — never in
/// domain code or deep inside widgets. Tests replace any of them:
///
/// ```dart
/// setUp(() async {
///   await getIt.reset();
///   getIt.registerSingleton<SettingsRepository>(FakeSettingsRepository());
/// });
/// ```
final GetIt getIt = GetIt.instance;

/// Composition root: registers every long-lived object in [getIt] once at
/// start-up — the only place that knows which implementation backs each
/// interface. Add new repositories / services to [register].
abstract final class Dependencies {
  static SettingsRepository get settingsRepository =>
      getIt<SettingsRepository>();

  /// Registers everything; no platform calls, so tests can run it.
  static void register(SharedPreferences prefs) {
    getIt
      ..registerSingleton<SharedPreferences>(prefs)
      // @@if api
      ..registerSingleton<ApiTokens>(backendApiTokens())
      ..registerLazySingleton<ItemsRepository>(ItemsRepository.new)
      // @@endif
      // @@if auth
      ..registerSingleton<AuthService>(BackendAuthService())
      // @@endif
      // @@if paywall
      ..registerSingleton<PurchasesService>(RevenueCatPurchasesService())
      // @@endif
      // @@if push
      ..registerSingleton<PushService>(FirebasePushService())
      // @@endif
      ..registerSingleton<SettingsRepository>(SettingsRepository(prefs));
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    register(prefs);
    await ReviewPrompt.recordLaunch(prefs);
    // @@if onboarding
    Onboarding.load(prefs);
    // @@endif
    // @@if api
    // The REST API's bearer token: the backend session's, or the API's own.
    ApiClient.tokens = getIt<ApiTokens>();
    // @@if auth
    ApiClient.onSessionExpired = () => Auth.user.value = null;
    // @@endif
    // @@endif
    // @@if auth
    await Auth.start(getIt<AuthService>());
    // @@endif
    // @@if paywall
    await Premium.start(getIt<PurchasesService>());
    // @@endif
    // @@if push
    await Push.start(getIt<PushService>());
    // @@endif
  }
}
// @@else
/// Composition root: long-lived objects created once at start-up.
/// Add new repositories / services here.
abstract final class Dependencies {
  static late final SettingsRepository settingsRepository;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SettingsRepository(prefs);
    await ReviewPrompt.recordLaunch(prefs);
    // @@if onboarding
    Onboarding.load(prefs);
    // @@endif
    // @@if api
    // The REST API's bearer token: the backend session's, or the API's own.
    ApiClient.tokens = backendApiTokens();
    // @@if auth
    ApiClient.onSessionExpired = () => Auth.user.value = null;
    // @@endif
    // @@endif
    // @@if auth
    await Auth.start(BackendAuthService());
    // @@endif
    // @@if paywall
    await Premium.start(RevenueCatPurchasesService());
    // @@endif
    // @@if push
    await Push.start(FirebasePushService());
    // @@endif
  }
}
// @@endif
