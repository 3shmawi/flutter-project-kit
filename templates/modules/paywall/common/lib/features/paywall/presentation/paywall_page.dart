import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/legal/legal_links.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
import 'package:__PROJECT_NAME__/features/paywall/presentation/paywall_view.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Loads the plans and wires [PaywallView] to [Premium.service].
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  List<PaywallPlan> _plans = const [];
  bool _loading = true;
  bool _busy = false;
  AppFailure? _failure;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(Analytics.capture('paywall_viewed'));
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await Premium.service.plans();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(:final value):
          _plans = value;
        case Failed(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _buy(PaywallPlan plan) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await Premium.service.buy(plan);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _busy = false;
      switch (result) {
        case Success():
          unawaited(
            Analytics.capture('purchase_completed', {
              'plan': plan.period.name,
            }),
          );
        case Failed(:final failure):
          _message = failure.message(l10n);
          if (failure case PurchaseFailure(
            reason: PurchaseFailureReason.cancelled,
          )) {
            return;
          }
          unawaited(
            Analytics.capture('purchase_failed', {'plan': plan.period.name}),
          );
      }
    });
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await Premium.service.restore();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _busy = false;
      _message = switch (result) {
        Success(value: true) => l10n.paywallRestored,
        Success() => l10n.paywallNothingToRestore,
        Failed(:final failure) => failure.message(l10n),
      };
    });
    if (result case Success(value: true)) {
      unawaited(Analytics.capture('purchases_restored'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Premium.active,
      builder: (context, isPremium, _) => PaywallView(
        plans: _plans,
        isPremium: isPremium,
        loading: _loading,
        busy: _busy,
        failure: _failure,
        message: _message,
        onBuy: (plan) => unawaited(_buy(plan)),
        onRestore: () => unawaited(_restore()),
        onRetry: () => unawaited(_load()),
        onOpenTerms: _open(LegalLinks.terms),
        onOpenPrivacy: _open(LegalLinks.privacy),
      ),
    );
  }
}

VoidCallback? _open(Uri? url) =>
    url == null ? null : () => unawaited(openLegalPage(url));
