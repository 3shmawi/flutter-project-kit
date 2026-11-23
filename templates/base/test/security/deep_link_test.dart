import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/router/app_router.dart';
import 'package:__PROJECT_NAME__/core/router/not_found_page.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
// @@if auth
import 'package:__PROJECT_NAME__/features/auth/presentation/account_page.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/sign_in_page.dart';
// @@endif
import 'package:__PROJECT_NAME__/features/home/presentation/home_page.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Deep links are untrusted input: unknown or crafted paths must land on a
/// safe screen, never crash or open something unexpected.
void main() {
  Future<void> pumpRouter(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1125, 2436)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppUi.testWrap(
        ScreenUtilInit(
        designSize: AppDimens.designSize,
        builder: (context, _) => MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unknown and crafted paths show the not-found page', (
    tester,
  ) async {
    await pumpRouter(tester);

    for (final path in [
      '/does-not-exist',
      '/settings/../../etc/passwd',
      '/%2e%2e/admin',
    ]) {
      appRouter.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(NotFoundPage), findsOneWidget, reason: path);
    }
  });

  testWidgets('query parameters cannot redirect the app', (tester) async {
    await pumpRouter(tester);

    appRouter.go('/?redirect=https://evil.example.com');
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
  // @@if auth

  group('sign-in', () {
    tearDown(() => Auth.user.value = null);

    testWidgets('signed-out users cannot open signed-in-only screens', (
      tester,
    ) async {
      await pumpRouter(tester);

      for (final path in ['/account', '/account/anything', '/new-password']) {
        appRouter.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(SignInPage), findsOneWidget, reason: path);
        expect(find.byType(AccountPage), findsNothing, reason: path);
      }
    });

    testWidgets('?from= after sign-in never leaves the app', (tester) async {
      Auth.user.value = const AppUser(id: 'user-1');
      await pumpRouter(tester);

      for (final from in [
        '//evil.example.com',
        'https://evil.example.com',
        r'/\evil.example.com',
      ]) {
        appRouter.go(Uri(path: '/sign-in', queryParameters: {'from': from}).toString());
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget, reason: from);
      }
    });
  });
  // @@endif
}
