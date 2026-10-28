import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/app/app_shell.dart';
import 'package:__PROJECT_NAME__/core/di/dependencies.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_controller.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_scope.dart';

/// Root widget: owns app-wide controllers and exposes them with scopes.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SettingsController _settings = SettingsController(
    Dependencies.settingsRepository,
  );

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => AppShell(settings: _settings.settings),
      ),
    );
  }
}
