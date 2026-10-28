import 'package:flutter/widgets.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/settings_controller.dart';

/// Makes the [SettingsController] available below it; widgets that call
/// [SettingsScope.of] rebuild when the settings change.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    required SettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found in the widget tree.');
    return scope!.notifier!;
  }
}
