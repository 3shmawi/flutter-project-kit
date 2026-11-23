import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/auth/auth_redirect.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';

void main() {
  group('authRedirect', () {
    test('sends signed-out users from signed-in-only paths to sign-in', () {
      final to = authRedirect(Uri.parse(AppRoutes.account), signedIn: false);
      expect(to, isNotNull);
      final uri = Uri.parse(to!);
      expect(uri.path, AppRoutes.signIn);
      expect(uri.queryParameters['from'], AppRoutes.account);
    });

    test('protects nested paths under a signed-in-only path', () {
      expect(isSignedInOnly('${AppRoutes.account}/edit'), isTrue);
      expect(isSignedInOnly('${AppRoutes.account}x'), isFalse);
    });

    test('lets everyone open public paths', () {
      expect(authRedirect(Uri.parse(AppRoutes.home), signedIn: false), isNull);
      expect(
        authRedirect(Uri.parse(AppRoutes.settings), signedIn: false),
        isNull,
      );
      expect(authRedirect(Uri.parse(AppRoutes.signIn), signedIn: false), isNull);
    });

    test('signed-in users on sign-in go back to where they were going', () {
      final uri = Uri(
        path: AppRoutes.signIn,
        queryParameters: {'from': AppRoutes.account},
      );
      expect(authRedirect(uri, signedIn: true), AppRoutes.account);
      expect(
        authRedirect(Uri.parse(AppRoutes.signIn), signedIn: true),
        AppRoutes.home,
      );
    });

    test('a password-reset link leads to the new-password screen', () {
      expect(
        authRedirect(
          Uri.parse(AppRoutes.home),
          signedIn: true,
          passwordRecovery: true,
        ),
        AppRoutes.newPassword,
      );
      expect(
        authRedirect(
          Uri.parse(AppRoutes.newPassword),
          signedIn: true,
          passwordRecovery: true,
        ),
        isNull,
      );
    });
  });

  group('safeReturnPath (hostile ?from= values)', () {
    for (final from in [
      null,
      '',
      'https://evil.example.com',
      '//evil.example.com',
      '//evil.example.com/account',
      r'/\evil.example.com',
      'javascript:alert(1)',
      'evil.example.com/account',
      AppRoutes.signIn,
      '${AppRoutes.signIn}?from=//evil.example.com',
    ]) {
      test('"$from" → home', () {
        expect(safeReturnPath(from), AppRoutes.home);
      });
    }

    test('keeps paths inside the app, with their query', () {
      expect(safeReturnPath(AppRoutes.account), AppRoutes.account);
      expect(safeReturnPath('/settings?tab=2'), '/settings?tab=2');
    });
  });

  group('AuthInput', () {
    test('accepts normal emails and trims spaces', () {
      expect(AuthInput.isEmail('a@b.co'), isTrue);
      expect(AuthInput.isEmail('  name.surname+tag@example.com '), isTrue);
    });

    test('rejects empty, malformed, oversized and injection-like emails', () {
      for (final email in [
        '',
        'plain',
        'a@b',
        'a b@c.com',
        "' OR 1=1 --",
        '<script>@x.com',
        '${'a' * 250}@example.com',
      ]) {
        expect(AuthInput.isEmail(email), isFalse, reason: email);
      }
    });

    test('passwords need 8 to 128 characters', () {
      expect(AuthInput.isPassword('1234567'), isFalse);
      expect(AuthInput.isPassword('12345678'), isTrue);
      expect(AuthInput.isPassword('x' * 128), isTrue);
      expect(AuthInput.isPassword('x' * 129), isFalse);
    });
  });
}
