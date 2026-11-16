# Feature: settings (language & theme)

## What it does
Lets the user choose the app language (device default, English, Arabic) and
theme (system, light, dark). Choices apply instantly and are saved on the
device. Arabic switches the whole UI to right-to-left.

Layout (the iOS settings look): groups of compact rows on cards, each
group's name above it in small muted bold (`SettingsSectionHeader`,
`SettingsGroup`, `SettingsRow` in `widgets/settings_tiles.dart`). A row has
an icon, its label at the start, the current value at the end and a chevron
(mirrors in RTL) when it opens something.
- **Appearance:** Language and Theme show the current choice and open a
  sheet to pick (`showSettingsChoice`, `SettingsChoiceRow` with a check).
  Closing the sheet changes nothing.
- **About:** the version (reads left to right in Arabic too, `1.2.3 (45)`),
  the privacy policy and terms (the `website/` pages, `LegalLinks` in
  `lib/core/legal/legal_links.dart`; hidden until the website has an https
  address) and open-source licenses (Flutter's licenses page).

## Architecture (__ARCHITECTURE__, state: __STATE__)
- Model: `lib/__SETTINGS_MODEL_PATH__`
- Repository: `lib/__SETTINGS_REPO_PATH__` (SharedPreferences)
- State holder: `lib/features/settings/presentation/` (__STATE_LABEL__)
- UI: `settings_view.dart` is pure UI (state in, callbacks out);
  `settings_page.dart` connects it to the state holder.
- Route: `/settings` (`AppRoutes.settings`).

## Tests
- Repository: `test/features/settings/data/`
- State holder: `test/features/settings/presentation/`
- View: `test/features/settings/presentation/settings_view_test.dart`
- Legal links: `test/core/legal/legal_links_test.dart`
- Integration: `integration_test/app_test.dart` (home → settings → Arabic)
