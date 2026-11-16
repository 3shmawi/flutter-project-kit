import 'dart:async';

import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/legal/legal_links.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_scope.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    return SettingsView(
      settings: controller.settings,
      onLocaleChanged: controller.setLocale,
      onThemeModeChanged: controller.setThemeMode,
      onOpenPrivacy: _open(LegalLinks.privacy),
      onOpenTerms: _open(LegalLinks.terms),
      onOpenLicenses: () => showLicensePage(context: context),
    );
  }
}

/// Opens [url] in the browser; null (row hidden) while there's no website.
VoidCallback? _open(Uri? url) =>
    url == null ? null : () => unawaited(openLegalPage(url));
