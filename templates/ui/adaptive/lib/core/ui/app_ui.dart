import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';

/// The app's UI style: adaptive (Material on Android, Cupertino touches on
/// iOS). Screens use these wrappers, never a style-specific widget, so the
/// whole app can switch style (e.g. to Liquid Glass) in this one file.
abstract final class AppUi {
  static const style = 'adaptive';

  static Future<void> initialize() async {}

  static Widget wrap(Widget app) => app;

  /// Tests render the same widgets.
  static Widget testWrap(Widget child) => child;
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title == null ? null : Text(title!),
        actions: actions,
      ),
      body: body,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(child: child);
}

/// An icon button with a tooltip (also its accessibility label).
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
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
      style: context.isCupertino
          ? IconButton.styleFrom(splashFactory: NoSplash.splashFactory)
          : null,
    );
  }
}
