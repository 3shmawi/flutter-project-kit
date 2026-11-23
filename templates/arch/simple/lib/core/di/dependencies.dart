import 'package:__PROJECT_NAME__/features/settings/data/settings_repository.dart';
import 'package:__PROJECT_NAME__/core/review/review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
// @@if api
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/backend_api_tokens.dart';
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
