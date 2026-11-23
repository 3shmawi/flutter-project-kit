import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_REPO_PATH__';
import 'package:__PROJECT_NAME__/core/di/dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';
// @@if api
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/features/items/data/items_repository.dart';
// @@endif
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
// @@endif
// @@if paywall
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
// @@endif
// @@if push
import 'package:__PROJECT_NAME__/core/push/push.dart';
// @@endif

class _FakeSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(getIt.reset);

  test('registers every long-lived object once', () async {
    Dependencies.register(await SharedPreferences.getInstance());

    expect(getIt.isRegistered<SharedPreferences>(), isTrue);
    expect(Dependencies.settingsRepository, same(getIt<SettingsRepository>()));
    // @@if api
    expect(getIt.isRegistered<ApiTokens>(), isTrue);
    expect(getIt<ItemsRepository>(), same(getIt<ItemsRepository>()));
    // @@endif
    // @@if auth
    expect(getIt.isRegistered<AuthService>(), isTrue);
    // @@endif
    // @@if paywall
    expect(getIt.isRegistered<PurchasesService>(), isTrue);
    // @@endif
    // @@if push
    expect(getIt.isRegistered<PushService>(), isTrue);
    // @@endif
  });

  test('registering twice is a mistake get_it reports', () async {
    final prefs = await SharedPreferences.getInstance();
    Dependencies.register(prefs);
    expect(() => Dependencies.register(prefs), throwsA(anything));
  });

  test('tests swap in a fake', () async {
    Dependencies.register(await SharedPreferences.getInstance());
    final fake = _FakeSettingsRepository();
    await getIt.unregister<SettingsRepository>();
    getIt.registerSingleton<SettingsRepository>(fake);

    expect(Dependencies.settingsRepository, same(fake));
  });
}
