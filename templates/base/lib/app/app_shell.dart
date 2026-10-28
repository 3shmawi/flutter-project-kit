import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:__PROJECT_NAME__/__SETTINGS_MODEL_PATH__';
import 'package:__PROJECT_NAME__/core/router/app_router.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_theme.dart';
import 'package:__PROJECT_NAME__/core/update/app_update_listener.dart';
import 'package:__PROJECT_NAME__/core/widgets/offline_banner.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// The MaterialApp, configured once: screen scaling, themes, localization
/// (Arabic → RTL automatically), routing and the update gate.
class AppShell extends StatelessWidget {
  const AppShell({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppDimens.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        locale: settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppUpdateListener(
          child: OfflineBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
