import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Shows [child] to premium users; everyone else sees [locked] (or a card
/// that opens the paywall). Wrap any premium-only part of a screen:
///
/// ```dart
/// PremiumGate(child: ExportButton())
/// ```
///
/// The store is the source of truth: [Premium.active] follows RevenueCat.
/// Content that must stay private (not just hidden) also needs a server
/// check — see docs/features/paywall.md.
class PremiumGate extends StatelessWidget {
  const PremiumGate({required this.child, this.locked, super.key});

  final Widget child;
  final Widget? locked;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Premium.active,
      builder: (context, isPremium, _) =>
          isPremium ? child : (locked ?? const PremiumLockedCard()),
    );
  }
}

/// "This is a Premium feature" + a button to the paywall.
class PremiumLockedCard extends StatelessWidget {
  const PremiumLockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.premiumLocked, textAlign: TextAlign.center),
            SizedBox(height: AppDimens.sm),
            AdaptiveButton(
              key: const Key('premium_unlock'),
              onPressed: () =>
                  unawaited(context.push<void>(AppRoutes.paywall)),
              child: Text(l10n.premiumUnlock),
            ),
          ],
        ),
      ),
    );
  }
}
