import 'package:flutter/widgets.dart';
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
    );
  }
}
