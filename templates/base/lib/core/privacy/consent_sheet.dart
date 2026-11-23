import 'dart:async';

import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/config/env.dart';
import 'package:__PROJECT_NAME__/core/privacy/consent.dart';
import 'package:__PROJECT_NAME__/core/router/app_router.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// The question itself: what is collected, why, and that it can be changed
/// later. Both answers look the same (no nudging, as GDPR guidance asks).
class ConsentSheet extends StatelessWidget {
  const ConsentSheet({required this.onChoice, super.key});

  final ValueChanged<ConsentChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.lg,
        0,
        AppDimens.lg,
        AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.consentTitle, style: AppTextStyles.title),
          ),
          SizedBox(height: AppDimens.sm),
          Text(l10n.consentBody, style: AppTextStyles.body),
          SizedBox(height: AppDimens.lg),
          Row(
            spacing: AppDimens.sm,
            children: [
              Expanded(
                child: AdaptiveButton(
                  key: const Key('consent_deny'),
                  onPressed: () => onChoice(ConsentChoice.denied),
                  child: Text(l10n.consentDeny),
                ),
              ),
              Expanded(
                child: AdaptiveButton(
                  key: const Key('consent_allow'),
                  onPressed: () => onChoice(ConsentChoice.granted),
                  child: Text(l10n.consentAllow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks once, on the home screen (after onboarding, never on top of
/// another screen or the update dialog's launch), when there is something
/// to ask about: a PostHog key or a Clarity id in the env file. Closing the
/// sheet without answering asks again next launch; nothing is collected
/// meanwhile.
class ConsentListener extends StatefulWidget {
  const ConsentListener({required this.child, super.key});

  final Widget child;

  /// An analytics SDK is set up in this build's env file.
  static bool get isNeeded =>
      Analytics.isConfigured || Env.clarityProjectId.isNotEmpty;

  @override
  State<ConsentListener> createState() => _ConsentListenerState();
}

class _ConsentListenerState extends State<ConsentListener> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    if (!ConsentListener.isNeeded) return;
    appRouter.routerDelegate.addListener(_maybeAsk);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_maybeAsk);
    super.dispose();
  }

  void _maybeAsk() {
    if (_asked || Consent.analytics.value != ConsentChoice.unknown) return;
    final location = appRouter.routerDelegate.currentConfiguration.uri.path;
    final context = rootNavigatorKey.currentContext;
    if (location != AppRoutes.home || context == null) return;
    _asked = true;
    appRouter.routerDelegate.removeListener(_maybeAsk);
    unawaited(
      showAppSheet<void>(
        context,
        builder: (sheetContext) => ConsentSheet(
          onChoice: (choice) {
            unawaited(Consent.set(choice));
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
