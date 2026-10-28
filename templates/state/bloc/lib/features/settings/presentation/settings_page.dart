import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_cubit.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_view.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    return SettingsView(
      settings: cubit.state,
      onLocaleChanged: cubit.setLocale,
      onThemeModeChanged: cubit.setThemeMode,
    );
  }
}
