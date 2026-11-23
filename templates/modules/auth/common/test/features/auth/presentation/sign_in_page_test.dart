import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/sign_in_page.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService();
    Auth.service = auth;
    Auth.user.value = null;
  });
  tearDown(() => Auth.service = const UnconfiguredAuthService());

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byKey(const Key('sign_in_email')), email);
    await tester.enterText(find.byKey(const Key('sign_in_password')), password);
    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();
  }

  group(SignInPage, () {
    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(const SignInPage());
      await tester.expectAccessible();
    });

    testWidgets('signs in with a valid email and password', (tester) async {
      await tester.pumpApp(const SignInPage());
      await fill(tester, ' ada@example.com ', 'correct-horse');

      expect(auth.calls, ['signInWithEmail']);
      expect(Auth.user.value?.email, 'ada@example.com');
    });

    testWidgets('shows a readable error for a wrong password', (tester) async {
      await tester.pumpApp(const SignInPage());
      await fill(tester, 'ada@example.com', 'wrong-password');

      expect(find.text(l10nEn.authErrorInvalidCredentials), findsOneWidget);
      expect(Auth.user.value, isNull);
    });

    testWidgets('checks the input before calling the backend', (tester) async {
      await tester.pumpApp(const SignInPage());

      for (final (email, password) in [
        ('', ''),
        ('not-an-email', 'correct-horse'),
        ("' OR 1=1 --", 'correct-horse'),
        ('ada@example.com', 'short'),
      ]) {
        await fill(tester, email, password);
      }

      expect(auth.calls, isEmpty);
      expect(find.text(l10nEn.authPasswordTooShort(8)), findsOneWidget);
    });

    testWidgets('fields cap oversized input', (tester) async {
      await tester.pumpApp(const SignInPage());
      await tester.enterText(
        find.byKey(const Key('sign_in_password')),
        'x' * 500,
      );
      await tester.enterText(
        find.byKey(const Key('sign_in_email')),
        '${'a' * 500}@example.com',
      );
      final password = tester.widget<TextField>(
        find.byKey(const Key('sign_in_password')),
      );
      final email = tester.widget<TextField>(
        find.byKey(const Key('sign_in_email')),
      );
      expect(password.controller!.text.length, 128);
      expect(email.controller!.text.length, lessThanOrEqualTo(254));
    });

    testWidgets('creating an account asks to confirm the email', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage());
      await tester.tap(find.byKey(const Key('sign_in_switch_mode')));
      await tester.pumpAndSettle();
      await fill(tester, 'new@example.com', 'correct-horse');

      expect(auth.calls, ['signUpWithEmail']);
      expect(find.text(l10nEn.authConfirmEmailSent), findsOneWidget);
    });

    testWidgets('forgot password sends the reset email', (tester) async {
      await tester.pumpApp(const SignInPage());
      await tester.enterText(
        find.byKey(const Key('sign_in_email')),
        'ada@example.com',
      );
      await tester.tap(find.byKey(const Key('sign_in_forgot')));
      await tester.pumpAndSettle();

      expect(auth.calls, ['sendPasswordReset']);
      expect(find.text(l10nEn.authResetSent), findsOneWidget);
    });

    testWidgets('hides social buttons that are not set up', (tester) async {
      await tester.pumpApp(const SignInPage());
      expect(find.byKey(const Key('sign_in_apple')), findsNothing);
      expect(find.byKey(const Key('sign_in_google')), findsNothing);
    });

    testWidgets('a closed Apple / Google sheet shows no error', (tester) async {
      Auth.service = auth = FakeAuthService(canUseGoogle: true)
        ..nextFailure = const AuthFailure(AuthFailureReason.cancelled);
      await tester.pumpApp(const SignInPage());
      await tester.tap(find.byKey(const Key('sign_in_google')));
      await tester.pumpAndSettle();

      expect(auth.calls, ['signInWithGoogle']);
      expect(find.byKey(const Key('sign_in_error')), findsNothing);
    });

    testWidgets('works right to left in Arabic', (tester) async {
      await tester.pumpApp(const SignInPage(), locale: const Locale('ar'));
      expect(
        Directionality.of(tester.element(find.byType(TextField).first)),
        TextDirection.rtl,
      );
    });
  });
}
