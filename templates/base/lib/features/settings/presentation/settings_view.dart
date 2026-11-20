import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Language, theme and About. Pure UI: state comes in, changes go out
/// through callbacks, so it works with any state-management choice.
///
/// Groups of compact rows on cards, each group's name above it (the iOS
/// settings layout): a row shows its current value at the end and opens a
/// sheet to pick; closing the sheet changes nothing.
class SettingsView extends StatelessWidget {
  const SettingsView({
    required this.settings,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.onOpenPrivacy,
    this.onOpenTerms,
    this.onOpenLicenses,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// The privacy policy and terms on the website; each row is hidden while
  /// its callback is null.
  final VoidCallback? onOpenPrivacy;
  final VoidCallback? onOpenTerms;

  /// Flutter's licenses page (fonts, packages); hidden while null.
  final VoidCallback? onOpenLicenses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languages = <(String, Locale?)>[
      (l10n.settingsLanguageSystem, null),
      (l10n.languageEnglish, const Locale('en')),
      (l10n.languageArabic, const Locale('ar')),
    ];
    final languageIndex = switch (settings.locale?.languageCode) {
      'en' => 1,
      'ar' => 2,
      _ => 0,
    };
    String themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
    return AppScaffold(
      title: l10n.settingsTitle,
      body: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppDimens.md,
          0,
          AppDimens.md,
          AppDimens.xl,
        ),
        children: [
          SettingsSectionHeader(l10n.settingsAppearance),
          SettingsGroup(
            children: [
              SettingsRow(
                key: const Key('settings_language'),
                label: l10n.settingsLanguage,
                icon: AdaptiveIcons.language(context),
                value: languages[languageIndex].$1,
                onTap: () async {
                  final picked = await showSettingsChoice(
                    context,
                    title: l10n.settingsLanguage,
                    choices: [for (final l in languages) l.$1],
                    selected: languageIndex,
                  );
                  if (picked != null) onLocaleChanged(languages[picked].$2);
                },
              ),
              SettingsRow(
                key: const Key('settings_theme'),
                label: l10n.settingsTheme,
                icon: AdaptiveIcons.theme(context),
                value: themeLabel(settings.themeMode),
                onTap: () async {
                  final picked = await showSettingsChoice(
                    context,
                    title: l10n.settingsTheme,
                    choices: [for (final m in ThemeMode.values) themeLabel(m)],
                    selected: settings.themeMode.index,
                  );
                  if (picked != null) {
                    onThemeModeChanged(ThemeMode.values[picked]);
                  }
                },
              ),
            ],
          ),
          SettingsSectionHeader(l10n.settingsAbout),
          SettingsGroup(
            children: [
              const SettingsVersionTile(),
              if (onOpenPrivacy != null)
                SettingsRow(
                  key: const Key('settings_privacy'),
                  label: l10n.settingsPrivacy,
                  icon: AdaptiveIcons.privacy(context),
                  onTap: onOpenPrivacy,
                ),
              if (onOpenTerms != null)
                SettingsRow(
                  key: const Key('settings_terms'),
                  label: l10n.settingsTerms,
                  icon: AdaptiveIcons.terms(context),
                  onTap: onOpenTerms,
                ),
              if (onOpenLicenses != null)
                SettingsRow(
                  key: const Key('settings_licenses'),
                  label: l10n.settingsLicenses,
                  icon: AdaptiveIcons.licenses(context),
                  onTap: onOpenLicenses,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
