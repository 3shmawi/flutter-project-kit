import 'dart:async';

import 'package:flutter/material.dart';
// @@if auth|paywall
import 'package:go_router/go_router.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
// @@endif
// @@if paywall
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/privacy/consent.dart';
import 'package:__PROJECT_NAME__/core/privacy/consent_sheet.dart';
// @@if push
import 'package:__PROJECT_NAME__/core/push/push.dart';
// @@endif
// @@if auth|paywall
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
// @@endif
import 'package:__PROJECT_NAME__/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Settings groups that wire themselves to a service: the project's modules
/// (sign-in, paid features, notifications) and Privacy. The settings page
/// stays the same whatever modules the app has.
class SettingsModuleSections extends StatelessWidget {
  const SettingsModuleSections({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // @@if auth
        SettingsSectionHeader(l10n.settingsAccount),
        SettingsGroup(
          children: [
            ValueListenableBuilder<AppUser?>(
              valueListenable: Auth.user,
              builder: (context, user, _) => SettingsRow(
                key: const Key('settings_account'),
                label: user == null ? l10n.settingsSignIn : l10n.accountTitle,
                value: user?.email,
                icon: AdaptiveIcons.account(context),
                onTap: () => unawaited(
                  context.push<void>(
                    user == null ? AppRoutes.signIn : AppRoutes.account,
                  ),
                ),
              ),
            ),
          ],
        ),
        // @@endif
        // @@if paywall
        SettingsSectionHeader(l10n.settingsPremium),
        SettingsGroup(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: Premium.active,
              builder: (context, isPremium, _) => SettingsRow(
                key: const Key('settings_premium'),
                label: l10n.settingsPremium,
                value: isPremium
                    ? l10n.settingsPremiumActive
                    : l10n.settingsPremiumUpgrade,
                icon: AdaptiveIcons.premium(context),
                onTap: () =>
                    unawaited(context.push<void>(AppRoutes.paywall)),
              ),
            ),
            SettingsRow(
              key: const Key('settings_restore_purchases'),
              label: l10n.settingsRestorePurchases,
              icon: AdaptiveIcons.restore(context),
              onTap: () => unawaited(_restore(context)),
            ),
          ],
        ),
        // @@endif
        // @@if push
        SettingsSectionHeader(l10n.settingsNotifications),
        SettingsGroup(
          children: [
            ValueListenableBuilder<PushPermission>(
              valueListenable: Push.permission,
              builder: (context, permission, _) => SettingsRow(
                key: const Key('settings_notifications'),
                label: l10n.settingsNotifications,
                icon: AdaptiveIcons.notifications(context),
                value: switch (permission) {
                  PushPermission.granted => l10n.settingsNotificationsOn,
                  PushPermission.denied => l10n.settingsNotificationsOff,
                  PushPermission.notDetermined =>
                    l10n.settingsNotificationsTurnOn,
                  PushPermission.unsupported =>
                    l10n.settingsNotificationsUnavailable,
                },
                onTap: permission == PushPermission.notDetermined
                    ? () => unawaited(Push.service.requestPermission())
                    : permission == PushPermission.denied
                    ? () => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsNotificationsDeniedHelp),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        // @@endif
        // Only when an analytics SDK is set up in the env file.
        if (ConsentListener.isNeeded) ...[
          SettingsSectionHeader(l10n.settingsPrivacySection),
          SettingsGroup(
            children: [
              ValueListenableBuilder<ConsentChoice>(
                valueListenable: Consent.analytics,
                builder: (context, choice, _) => SettingsSwitchRow(
                  key: const Key('settings_usage_data'),
                  label: l10n.settingsUsageData,
                  subtitle: l10n.settingsUsageDataHelp,
                  icon: AdaptiveIcons.privacy(context),
                  value: choice == ConsentChoice.granted,
                  onChanged: (on) => unawaited(
                    Consent.set(
                      on ? ConsentChoice.granted : ConsentChoice.denied,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  // @@if paywall

  /// Restore from Settings too (Apple asks for it to be easy to find).
  static Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    final result = await Premium.service.restore();
    final message = switch (result) {
      Success(value: true) => l10n.paywallRestored,
      Success() => l10n.paywallNothingToRestore,
      Failed(:final failure) => failure.message(l10n),
    };
    if (message.isNotEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }
  // @@endif
}
