import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/features/onboarding/data/onboarding.dart';
import 'package:__PROJECT_NAME__/features/onboarding/presentation/onboarding_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  const slides = [
    OnboardingSlide(icon: Icons.circle, title: 'One', body: 'First'),
    OnboardingSlide(icon: Icons.circle, title: 'Two', body: 'Second'),
    OnboardingSlide(icon: Icons.circle, title: 'Three', body: 'Third'),
  ];

  group('onboardingRedirect', () {
    test('sends a new install from home to the welcome screens', () {
      expect(
        onboardingRedirect(Uri.parse(AppRoutes.home), seen: false),
        AppRoutes.welcome,
      );
    });

    test('lets deep links through, and stops once seen', () {
      expect(
        onboardingRedirect(Uri.parse(AppRoutes.settings), seen: false),
        isNull,
      );
      expect(onboardingRedirect(Uri.parse(AppRoutes.home), seen: true), isNull);
    });
  });

  test('completing is saved on the device', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Onboarding.load(prefs);
    expect(Onboarding.seen.value, isFalse);

    await Onboarding.complete();
    Onboarding.load(prefs);
    expect(Onboarding.seen.value, isTrue);
  });

  group(OnboardingView, () {
    testWidgets('Next walks through the pages, then Get started finishes', (
      tester,
    ) async {
      bool? skipped;
      await tester.pumpApp(
        OnboardingView(slides: slides, onDone: (s) => skipped = s),
      );
      expect(find.text('One'), findsOneWidget);
      expect(find.text(l10nEn.onboardingNext), findsOneWidget);

      for (final title in ['Two', 'Three']) {
        await tester.tap(find.byKey(const Key('onboarding_next')));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text(l10nEn.onboardingStart), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_next')));
      expect(skipped, isFalse);
    });

    testWidgets('Skip finishes at once', (tester) async {
      bool? skipped;
      await tester.pumpApp(
        OnboardingView(slides: slides, onDone: (s) => skipped = s),
      );
      await tester.tap(find.byKey(const Key('onboarding_skip')));
      expect(skipped, isTrue);
    });

    testWidgets('swipes follow the reading direction in Arabic', (
      tester,
    ) async {
      await tester.pumpApp(
        OnboardingView(slides: slides, onDone: (_) {}),
        locale: const Locale('ar'),
      );
      // In right-to-left the next page comes from the left.
      await tester.drag(
        find.byKey(const Key('onboarding_pages')),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(OnboardingView(slides: slides, onDone: (_) {}));
      await tester.expectAccessible();
    });
  });
}
