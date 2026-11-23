import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/account_page.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService();
    Auth.service = auth;
    Auth.user.value = const AppUser(id: 'user-1', email: 'ada@example.com');
  });
  tearDown(() {
    Auth.service = const UnconfiguredAuthService();
    Auth.user.value = null;
  });

  group(AccountPage, () {
    testWidgets('shows who is signed in', (tester) async {
      await tester.pumpApp(const AccountPage());
      expect(find.text('ada@example.com'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(const AccountPage());
      await tester.expectAccessible();
    });

    testWidgets('signs out', (tester) async {
      await tester.pumpApp(const AccountPage());
      await tester.tap(find.byKey(const Key('account_sign_out')));
      await tester.pumpAndSettle();

      expect(auth.calls, ['signOut']);
      expect(Auth.user.value, isNull);
    });

    testWidgets('deleting asks first; cancel keeps the account', (
      tester,
    ) async {
      await tester.pumpApp(const AccountPage());
      await tester.tap(find.byKey(const Key('account_delete')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.accountDeleteTitle), findsOneWidget);

      await tester.tap(find.byKey(const Key('account_delete_cancel')));
      await tester.pumpAndSettle();
      expect(auth.calls, isEmpty);
      expect(Auth.user.value, isNotNull);
    });

    testWidgets('deletes the account after confirming', (tester) async {
      await tester.pumpApp(const AccountPage());
      await tester.tap(find.byKey(const Key('account_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account_delete_confirm')));
      await tester.pumpAndSettle();

      expect(auth.calls, ['deleteAccount']);
      expect(Auth.user.value, isNull);
    });

    testWidgets('asks for a fresh sign-in when the backend requires it', (
      tester,
    ) async {
      auth.nextFailure = const AuthFailure(
        AuthFailureReason.recentLoginRequired,
      );
      await tester.pumpApp(const AccountPage());
      await tester.tap(find.byKey(const Key('account_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account_delete_confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.authErrorRecentLogin), findsOneWidget);
      expect(Auth.user.value, isNotNull);
    });
  });
}
