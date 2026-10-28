# Design

The UI is designed first in Claude (Design System + Design artifacts), then
built to match. Code never invents its own look.

| Source | Link |
|---|---|
| Design System (tokens, components, guidelines) | <!-- claude.ai/artifact/… --> |
| Screens (Design canvas) | <!-- claude.ai/artifact/… --> |
| App icon / store screenshots | <!-- claude.ai/artifact/… --> |

## Tokens → code
| Design System token | Code |
|---|---|
| Colors (light + dark) | `lib/core/theme/app_colors.dart` → `AppTheme` |
| Type scale, font family | `lib/core/theme/app_text_styles.dart` |
| Spacing, radius, sizes | `lib/core/theme/app_dimens.dart` |
| Components (buttons, cards, inputs…) | `lib/core/widgets/` (create as needed) |

When the Design System changes, update these files first, then screens.

## Screen checklist (each screen in the design → code)
- Matches the design at 375×812, and still works on a small phone (320 wide),
  a large phone and a tablet.
- Has all states: loading (skeleton/adaptive spinner), empty, error with
  retry, success, offline.
- Arabic RTL and dark mode checked.
- Touch targets ≥ 48×48, text contrast ≥ 4.5:1, works with large text
  (system font scale 1.3+), every icon button has a semantics label/tooltip.
- Motion: short (150–300 ms), purposeful; respects "reduce motion".
- Platform-adaptive: iOS look on iOS (Cupertino), Material on Android.
