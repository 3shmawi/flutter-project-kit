import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:__PROJECT_NAME__/core/legal/legal_links.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_controller.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsView(
      settings: ref.watch(settingsControllerProvider),
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
