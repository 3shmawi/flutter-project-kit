// @@if auth
import 'dart:async';

// @@endif
import 'package:flutter/material.dart';
// @@if auth
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
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
    // @@if auth
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
      ],
    );
  }
}
