import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// The paywall: plans with their store price, the renewal terms, Restore,
/// Terms and Privacy (all required by Apple 3.1.2 and Google Play).
/// Pure UI; [PaywallPage] does the buying.
class PaywallView extends StatefulWidget {
  const PaywallView({
    required this.plans,
    required this.isPremium,
    required this.onBuy,
    required this.onRestore,
    required this.onRetry,
    this.loading = false,
    this.busy = false,
    this.failure,
    this.message,
    this.onOpenTerms,
    this.onOpenPrivacy,
    super.key,
  });

  final List<PaywallPlan> plans;
  final bool isPremium;
  final ValueChanged<PaywallPlan> onBuy;
  final VoidCallback onRestore;
  final VoidCallback onRetry;

  /// Plans are loading.
  final bool loading;

  /// A purchase or restore is running.
  final bool busy;

  /// Loading the plans failed (shown with Try again).
  final AppFailure? failure;

  /// The result of the last purchase / restore.
  final String? message;

  /// Hidden while null (no website yet).
  final VoidCallback? onOpenTerms;
  final VoidCallback? onOpenPrivacy;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  String? _selectedId;

  PaywallPlan? get _selected {
    final plans = widget.plans;
    if (plans.isEmpty) return null;
    return plans.firstWhere(
      (p) => p.id == _selectedId,
      // Yearly first when there is one: the usual best value.
      orElse: () => plans.firstWhere(
        (p) => p.period == PlanPeriod.annual,
        orElse: () => plans.first,
      ),
    );
  }

  String _label(BuildContext context, PaywallPlan plan) {
    final l10n = context.l10n;
    return switch (plan.period) {
      PlanPeriod.weekly => l10n.paywallPlanWeekly,
      PlanPeriod.monthly => l10n.paywallPlanMonthly,
      PlanPeriod.annual => l10n.paywallPlanAnnual,
      PlanPeriod.lifetime => l10n.paywallPlanLifetime,
      PlanPeriod.other => plan.title,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final failure = widget.failure;
    final Widget body;
    if (widget.isPremium) {
      body = EmptyView(
        message: l10n.paywallActive,
        icon: AdaptiveIcons.premium(context),
      );
    } else if (widget.loading) {
      body = const LoadingView();
    } else if (failure != null) {
      body = ErrorView(failure: failure, onRetry: widget.onRetry);
    } else {
      final selected = _selected;
      body = ListView(
        padding: EdgeInsets.all(AppDimens.lg),
        children: [
          Text(
            l10n.paywallHeadline,
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.lg),
          if (widget.plans.isEmpty)
            Text(l10n.paywallEmpty, textAlign: TextAlign.center)
          else
            RadioGroup<String>(
              groupValue: selected?.id,
              onChanged: (id) {
                if (!widget.busy) setState(() => _selectedId = id);
              },
              child: Column(
                children: [
                  for (final plan in widget.plans)
                    AppCard(
                      child: RadioListTile<String>.adaptive(
                        key: Key('paywall_plan_${plan.id}'),
                        value: plan.id,
                        title: Text(_label(context, plan)),
                        secondary: Text(
                          plan.price,
                          style: AppTextStyles.label,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: AppDimens.lg),
          AdaptiveButton(
            key: const Key('paywall_continue'),
            onPressed: selected == null || widget.busy
                ? null
                : () => widget.onBuy(selected),
            child: widget.busy
                ? SizedBox.square(
                    dimension: AppDimens.iconMd,
                    child: const CircularProgressIndicator.adaptive(),
                  )
                : Text(l10n.paywallContinue),
          ),
          if (widget.message case final message? when message.isNotEmpty) ...[
            SizedBox(height: AppDimens.md),
            Text(
              message,
              key: const Key('paywall_message'),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: AppDimens.md),
          Text(
            l10n.paywallRenewalNote,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                key: const Key('paywall_restore'),
                onPressed: widget.busy ? null : widget.onRestore,
                child: Text(l10n.paywallRestore),
              ),
              if (widget.onOpenTerms case final onOpenTerms?)
                TextButton(
                  onPressed: onOpenTerms,
                  child: Text(l10n.settingsTerms),
                ),
              if (widget.onOpenPrivacy case final onOpenPrivacy?)
                TextButton(
                  onPressed: onOpenPrivacy,
                  child: Text(l10n.settingsPrivacy),
                ),
            ],
          ),
        ],
      );
    }
    return AppScaffold(title: l10n.paywallTitle, body: body);
  }
}
