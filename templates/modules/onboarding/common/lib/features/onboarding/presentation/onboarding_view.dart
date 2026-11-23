import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// One welcome page: an icon, a title and a sentence.
@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// Swipeable welcome pages with dots, Skip and Next / Get started.
/// Pure UI: [onDone] reports whether the user skipped. Swipes follow the
/// reading direction (right to left in Arabic).
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    required this.slides,
    required this.onDone,
    this.extraAction,
    super.key,
  });

  final List<OnboardingSlide> slides;
  final ValueChanged<bool> onDone;

  /// Shown on the last page above Get started (e.g. turn on notifications).
  final Widget? extraAction;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == widget.slides.length - 1;

  Future<void> _next() async {
    if (_isLast) {
      widget.onDone(false);
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('onboarding_skip'),
                onPressed: () => widget.onDone(true),
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                key: const Key('onboarding_pages'),
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final slide in widget.slides)
                    Padding(
                      padding: EdgeInsets.all(AppDimens.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            slide.icon,
                            size: AppDimens.iconMd * 4,
                            color: scheme.primary,
                          ),
                          SizedBox(height: AppDimens.xl),
                          Semantics(
                            header: true,
                            child: Text(
                              slide.title,
                              style: AppTextStyles.headline,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: AppDimens.md),
                          Text(
                            slide.body,
                            style: AppTextStyles.body.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: l10n.onboardingProgress(
                _index + 1,
                widget.slides.length,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.all(AppDimens.xs),
                      width: i == _index ? AppDimens.md : AppDimens.sm,
                      height: AppDimens.sm,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppDimens.sm),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppDimens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLast && widget.extraAction != null) ...[
                    widget.extraAction!,
                    SizedBox(height: AppDimens.sm),
                  ],
                  AdaptiveButton(
                    key: const Key('onboarding_next'),
                    onPressed: _next,
                    child: Text(
                      _isLast ? l10n.onboardingStart : l10n.onboardingNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
