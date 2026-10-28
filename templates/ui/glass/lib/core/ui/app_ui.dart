import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/theme/app_colors.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The app's UI style: Liquid Glass (iOS 26/27 look) on every platform,
/// via liquid_glass_widgets. Screens use these wrappers, never a glass
/// widget directly, so the style can change in this one file — e.g. to
/// Flutter's own Cupertino Liquid Glass when it ships.
///
/// Quality: premium (Impeller shader) on iOS, standard elsewhere; Reduce
/// Motion and Increase Contrast are respected automatically.
abstract final class AppUi {
  static const style = 'glass';

  static Future<void> initialize() => LiquidGlassWidgets.initialize();

  static Widget wrap(Widget app) => LiquidGlassWidgets.wrap(
    child: app,
    brightnessResolver: Theme.maybeBrightnessOf,
    theme: GlassThemeData.simple(
      blur: 10,
      thickness: 30,
      quality: defaultTargetPlatform == TargetPlatform.iOS
          ? GlassQuality.premium
          : GlassQuality.standard,
    ),
  );

  /// Tests (and accessibility checks) run with solid surfaces: the most
  /// readable variant, and no shader needed in flutter_test.
  static Widget testWrap(Widget child) =>
      GlassAccessibilityScope(reduceTransparency: true, child: child);
}

/// Glass needs something behind it: a soft gradient from the brand color.
/// Screens with photos pass their own [AppScaffold.background].
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.lerp(AppColors.primary, scheme.surface, 0.55)!,
            scheme.surface,
            Color.lerp(scheme.tertiary, scheme.surface, 0.7)!,
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions = const [],
    this.background,
    super.key,
  });

  final String? title;
  final List<Widget> actions;
  final Widget body;

  /// Defaults to [AppBackground]; pass a photo for image-rich screens.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final hasBar = title != null || actions.isNotEmpty || canPop;
    return GlassScaffold(
      background: background ?? const AppBackground(),
      appBar: hasBar
          ? GlassAppBar(
              // Back, title and actions share the title slot (no flex: the
              // slot's width may be unbounded).
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPop)
                    AppIconButton(
                      icon: AdaptiveIcons.back(context),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  if (title != null)
                    Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ...actions,
                  ],
                ],
              ),
            )
          : null,
      // Transparent Material: ListTile, InkWell, TextField… need one, and
      // GlassScaffold (unlike Scaffold) doesn't provide it.
      body: Material(
        type: MaterialType.transparency,
        child: SafeArea(child: body),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => GlassContainer.card(child: child);
}

/// A glass icon button with a tooltip (also its accessibility label).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // One semantics node with label + action, at least 48×48 (Android and
    // iOS tap-target guidelines).
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        onTap: onPressed,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: GlassButton(icon: Icon(icon), onTap: onPressed),
            ),
          ),
        ),
      ),
    );
  }
}
