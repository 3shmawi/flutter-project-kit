// @@if auth|paywall
import 'dart:async';

// @@endif
import 'package:flutter/material.dart';
// @@if auth|paywall
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
// @@endif
// @@if auth
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
// @@endif
// @@if paywall
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
// @@endif
// @@if auth|paywall
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';
// @@endif

/// Settings groups that come from the project's modules (sign-in, paid
/// features, notifications, privacy). Each wires itself to its service, so
/// the settings page stays the same whatever modules the app has.
class SettingsModuleSections extends StatelessWidget {
  const SettingsModuleSections({super.key});

  @override
  Widget build(BuildContext context) {
    // @@if auth|paywall
    final l10n = context.l10n;
    // @@endif
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
