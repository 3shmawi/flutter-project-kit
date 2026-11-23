import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
// @@if push
import 'package:__PROJECT_NAME__/core/push/push.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/features/onboarding/data/onboarding.dart';
import 'package:__PROJECT_NAME__/features/onboarding/presentation/onboarding_view.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// The first-launch welcome (`/welcome`). Edit the slides here: what the
/// app does, in three short pages, with the app's own words and icons.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingView(
      slides: [
        OnboardingSlide(
          icon: AdaptiveIcons.onboardingWelcome(context),
          title: l10n.onboardingTitle1,
          body: l10n.onboardingBody1,
        ),
        OnboardingSlide(
          icon: AdaptiveIcons.onboardingFeature(context),
          title: l10n.onboardingTitle2,
          body: l10n.onboardingBody2,
        ),
        OnboardingSlide(
          icon: AdaptiveIcons.onboardingReady(context),
          title: l10n.onboardingTitle3,
          body: l10n.onboardingBody3,
        ),
      ],
      // @@if push
      // The one place a new user meets notifications: asked here, in
      // context, never by surprise.
      extraAction: ValueListenableBuilder<PushPermission>(
        valueListenable: Push.permission,
        builder: (context, permission, _) =>
            permission == PushPermission.notDetermined
            ? OutlinedButton(
                key: const Key('onboarding_notifications'),
                onPressed: () => unawaited(Push.service.requestPermission()),
                child: Text(l10n.onboardingNotifications),
              )
            : const SizedBox.shrink(),
      ),
      // @@endif
      onDone: (skipped) {
        unawaited(
          Analytics.capture('onboarding_completed', {'skipped': skipped}),
        );
        unawaited(Onboarding.complete());
        context.go(AppRoutes.home);
      },
    );
  }
}
