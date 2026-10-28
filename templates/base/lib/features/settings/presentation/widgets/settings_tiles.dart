import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.md,
        AppDimens.lg,
        AppDimens.md,
        AppDimens.xs,
      ),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A single-choice row with a check mark when selected.
class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: AppTextStyles.body),
      trailing: selected
          ? Icon(
              AdaptiveIcons.check(context),
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
