import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/app/app_shell.dart';
import 'package:__PROJECT_NAME__/core/di/dependencies.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_cubit.dart';

/// Root widget: provides app-wide blocs, then builds the shell.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(Dependencies.settingsRepository),
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) => AppShell(settings: settings),
      ),
    );
  }
}
