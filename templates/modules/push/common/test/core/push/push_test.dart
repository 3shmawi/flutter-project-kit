import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/push/push.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/widgets/settings_module_sections.dart';

import '../../helpers/pump_app.dart';

class _FakePush implements PushService {
  int requests = 0;

  @override
  Future<void> start() async {}

  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    return Push.permission.value = PushPermission.granted;
  }
}

void main() {
  group('Push.routeOf (notification data is untrusted)', () {
    test('opens paths inside the app', () {
      expect(Push.routeOf({'route': '/settings'}), '/settings');
      expect(Push.routeOf({'route': '/'}), '/');
    });

    for (final route in [
      null,
      '',
      42,
      'settings',
      '//evil.example.com',
      'https://evil.example.com',
      'javascript:alert(1)',
      r'/\evil.example.com',
      '/${'a' * 600}',
    ]) {
      test('ignores ${route.toString().length > 40 ? 'a very long route' : route}', () {
        expect(Push.routeOf({'route': route}), isNull);
      });
    }
  });

  test('update topics follow the language', () {
    expect(Push.updatesTopic(const Locale('ar')), 'updates_ar');
    expect(Push.updatesTopic(const Locale('en')), 'updates_en');
    expect(Push.updatesTopic(const Locale('fr')), 'updates_en');
  });

  group('Settings → Notifications', () {
    late _FakePush push;

    setUp(() {
      push = _FakePush();
      Push.service = push;
      Push.permission.value = PushPermission.notDetermined;
    });
    tearDown(() {
      Push.service = const UnconfiguredPushService();
      Push.permission.value = PushPermission.unsupported;
    });

    testWidgets('asks for permission only when the user taps', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: SingleChildScrollView(child: SettingsModuleSections())),
      );
      expect(push.requests, 0);
      expect(find.text(l10nEn.settingsNotificationsTurnOn), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_notifications')));
      await tester.pumpAndSettle();

      expect(push.requests, 1);
      expect(find.text(l10nEn.settingsNotificationsOn), findsOneWidget);
    });

    testWidgets('when denied, explains where to turn them on', (tester) async {
      Push.permission.value = PushPermission.denied;
      await tester.pumpApp(
        const Scaffold(body: SingleChildScrollView(child: SettingsModuleSections())),
      );
      await tester.tap(find.byKey(const Key('settings_notifications')));
      await tester.pump();

      expect(push.requests, 0);
      expect(find.text(l10nEn.settingsNotificationsDeniedHelp), findsOneWidget);
    });
  });
}
