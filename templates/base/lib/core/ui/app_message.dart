import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';

/// A short message at the bottom of the screen ("Password updated."),
/// for every UI style: it doesn't need a Material `Scaffold` (the glass
/// style has none), and screen readers announce it.
///
/// After an `await`, the screen may be gone: take the messenger first.
/// ```dart
/// final message = appMessenger(context);
/// await save();
/// message(l10n.saved);
/// ```
void Function(String message) appMessenger(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  return (message) {
    if (overlay == null || !overlay.mounted || message.isEmpty) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppMessage(message: message, onDone: entry.remove),
    );
    overlay.insert(entry);
  };
}

/// [appMessenger] when nothing is awaited first.
void showAppMessage(BuildContext context, String message) =>
    appMessenger(context)(message);

class _AppMessage extends StatefulWidget {
  const _AppMessage({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_AppMessage> createState() => _AppMessageState();
}

class _AppMessageState extends State<_AppMessage>
    with SingleTickerProviderStateMixin {
  // Fade in, stay, fade out: one animation, so tests settle on their own.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..forward().whenComplete(widget.onDone);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 5),
    TweenSequenceItem(tween: ConstantTween(1), weight: 85),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 10),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PositionedDirectional(
      start: AppDimens.md,
      end: AppDimens.md,
      bottom: MediaQuery.paddingOf(context).bottom + AppDimens.lg,
      child: FadeTransition(
        opacity: _opacity,
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: scheme.inverseSurface,
            elevation: 6,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Padding(
              padding: EdgeInsets.all(AppDimens.md),
              child: Text(
                widget.message,
                style: AppTextStyles.body.copyWith(
                  color: scheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
