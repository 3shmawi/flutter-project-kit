import 'dart:async';

import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/core/ui/app_message.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/core/update/update_info.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the update in the app's own style: an optional update as a sheet
/// ("Update" / "Later", built on `showAppSheet`, so glass in the glass
/// style), a forced update as a full screen the user can't leave.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  if (info.isForce) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ForcedUpdatePage(info: info),
      ),
    );
  }
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => UpdateView(
      info: info,
      onLater: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

/// "What's new" as separate points: one per line, list markers removed.
List<String> changelogPoints(String changelog) => [
  for (final line in changelog.split('\n'))
    if (line.replaceFirst(RegExp(r'^\s*([-*•·]|\d+[.)])\s*'), '').trim()
        case final point when point.isNotEmpty)
      point,
];

/// The update's content, shared by the sheet and the forced screen.
class UpdateView extends StatelessWidget {
  const UpdateView({required this.info, this.onLater, super.key});

  final UpdateInfo info;

  /// Shown as "Later" for an optional update.
  final VoidCallback? onLater;

  Future<void> _openStore(BuildContext context) async {
    final message = appMessenger(context);
    final failed = context.l10n.errorUnknown;
    final uri = Uri.tryParse(info.config.storeUrl);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) message(failed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final arabic = changelogPoints(info.config.changelogAr);
    // No Arabic text yet (e.g. the daily auto-announce found none) → English.
    final points = isArabic && arabic.isNotEmpty
        ? arabic
        : changelogPoints(info.config.changelogEn);
    final current = info.current.toString();
    final latest = info.config.latest.toString();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.lg,
        AppDimens.sm,
        AppDimens.lg,
        AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppDimens.iconMd * 3,
              height: AppDimens.iconMd * 3,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AdaptiveIcons.update(context),
                size: AppDimens.iconMd * 1.5,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(height: AppDimens.md),
          Semantics(
            header: true,
            child: Text(
              info.isForce ? l10n.updateForceTitle : l10n.updateOptionalTitle,
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
          ),
          if (info.isForce) ...[
            SizedBox(height: AppDimens.sm),
            Text(
              l10n.updateForceMessage,
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: AppDimens.md),
          // "1.0.0 → 1.1.0" reads left to right in Arabic too; screen
          // readers get the full sentence.
          Semantics(
            label: l10n.updateVersions(current, latest),
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              spacing: AppDimens.sm,
              children: [
                _VersionChip(current, key: const Key('update_current')),
                Icon(
                  Icons.arrow_forward,
                  size: AppDimens.iconMd * 0.75,
                  color: scheme.onSurfaceVariant,
                ),
                _VersionChip(latest, key: const Key('update_latest'), emphasis: true),
              ],
            ),
          ),
          if (points.isNotEmpty) ...[
            SizedBox(height: AppDimens.lg),
            Text(l10n.updateWhatsNew, style: AppTextStyles.label),
            SizedBox(height: AppDimens.sm),
            for (final point in points)
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: AppDimens.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppDimens.sm,
                  children: [
                    Text('•', style: AppTextStyles.body),
                    Expanded(child: Text(point, style: AppTextStyles.body)),
                  ],
                ),
              ),
          ],
          SizedBox(height: AppDimens.lg),
          AdaptiveButton(
            key: const Key('update_now'),
            onPressed: () => unawaited(_openStore(context)),
            child: Text(l10n.updateNow),
          ),
          if (!info.isForce && onLater != null) ...[
            SizedBox(height: AppDimens.xs),
            TextButton(
              key: const Key('update_later'),
              onPressed: onLater,
              child: Text(l10n.updateLater),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip(this.version, {this.emphasis = false, super.key});

  final String version;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: emphasis ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(
        version,
        style: AppTextStyles.label.copyWith(
          color: emphasis ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
    );
  }
}

/// A forced update: the whole screen, no way back until the user updates.
class ForcedUpdatePage extends StatelessWidget {
  const ForcedUpdatePage({required this.info, super.key});

  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        body: Center(
          child: SingleChildScrollView(child: UpdateView(info: info)),
        ),
      ),
    );
  }
}
