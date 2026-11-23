import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/core/review/review_prompt.dart';
import 'package:__PROJECT_NAME__/core/router/app_router.dart';
import 'package:__PROJECT_NAME__/core/update/update_dialog.dart';
import 'package:__PROJECT_NAME__/core/update/update_info.dart';
import 'package:__PROJECT_NAME__/core/update/update_service.dart';

/// Checks for a new version once per launch and shows the update (sheet or forced screen).
class AppUpdateListener extends StatefulWidget {
  const AppUpdateListener({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends State<AppUpdateListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  Future<void> _check() async {
    final UpdateInfo? info = await UpdateService.check();
    if (info == null) {
      // No update to show: a good moment for the (flagged, rate-limited)
      // store rating sheet — never both in one launch.
      unawaited(ReviewPrompt.maybeAsk());
      return;
    }
    final BuildContext? navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    if (!navigatorContext.mounted) return;
    await showUpdateDialog(navigatorContext, info);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
