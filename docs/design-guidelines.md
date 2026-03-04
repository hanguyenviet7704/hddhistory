# Design Guidelines

**Last Updated:** 2026-02-27  
**Scope:** UI patterns and tokens used by this Flutter codebase

## 1. Design System Sources
Primary files:
- `lib/config/themes/colors.dart`
- `lib/config/themes/material_theme.dart`
- `lib/config/themes/text_theme.dart`
- `lib/config/themes/util_theme.dart`
- `lib/core/constants/gen/fonts.gen.dart`

Use these files as the source of truth for tokens and examples.

## 2. Color System
The app uses two complementary color layers:
1. `AppCustomColor` for product-specific tokens and gradients.
2. Material `ColorScheme` (`AppColorLight` / `AppColorDark`) for theme-level components.

### 2.1 AppCustomColor tokens (selected)
| Token | Hex | Usage |
| --- | --- | --- |
| `brandPrimary` | `#554FF0` | Brand-accent actions/labels |
| `textPrimary` | `#0D121C` | Primary content text |
| `textSecondary` | `#364152` | Secondary text |
| `textTertiary` | `#7F8EA4` | Tertiary/supporting text |
| `backgroundWhite` | `#FFFFFF` | Main surface background |
| `backgroundGray` | `#F5F7FB` | Secondary background |
| `borderDefault` | `#EBF0F7` | Default border tone |
| `successGreen` | `#41AE8C` | Success states |
| `errorRed` | `#E34646` | Error states |
| `feedbackStarActive` | `#F7C52B` | Feedback rating active state |

### 2.2 Material ColorScheme anchors (light theme)
| Token | Hex |
| --- | --- |
| `AppColorLight.primary` | `#F7704B` |
| `AppColorLight.secondary` | `#77574E` |
| `AppColorLight.tertiary` | `#6C5D2E` |
| `AppColorLight.surface` | `#FFFFFF` |
| `AppColorLight.error` | `#BA1A1A` |

### 2.3 Gradient tokens (selected)
- `AppCustomColor.gradientButton`
- `AppCustomColor.gradientBackground`
- `AppCustomColor.gradientAvatarBorder`
- `AppCustomColor.gradientRoleplay`

Use gradient tokens directly; avoid redefining gradient stop lists inline.

## 3. Typography
### 3.1 Font family
`AppFont.mulish` (`Mulish`) is the configured app font family.

### 3.2 Text scale
`AppStyle` defines reusable text styles from `text6` through `text56` and bold variants (`textBold14`, etc.).

Common sizes in active use:
- Small labels: `text10`, `text12`
- Body text: `text14`, `text16`
- Section emphasis: `text18`, `text20`, `text24`
- Display text: `text30+`

### 3.3 Sizing system
Text and layout values use `flutter_screenutil` units:
- text: `.sp`
- dimensions: `.w`, `.h`

## 4. Theming Guidelines
- Keep `ThemeData` creation in `material_theme.dart` / `util_theme.dart`.
- Read runtime colors from `AppTheme` when theme-aware behavior is required.
- Do not hardcode color literals in feature widgets when a token exists.

## 5. Component Usage Patterns
### Buttons and highlights
- Prefer shared widgets under `lib/core/utils/button/`.
- For branded buttons, use gradient tokens from `AppCustomColor.gradientButton`.

### Text
- Prefer `AppStyle` presets before custom `TextStyle` construction.
- If custom style is required, start from an existing preset and `copyWith`.

### Icons and assets
- Use generated asset/font references from `lib/core/constants/gen/`.
- Do not embed raw asset path strings in new UI code when generated constants exist.

## 6. Example Snippets (Code-Accurate)
### Token-based card style
```dart
Container(
  decoration: BoxDecoration(
    color: AppCustomColor.backgroundWhite,
    border: Border.all(color: AppCustomColor.borderDefault),
    borderRadius: BorderRadius.circular(12.r),
  ),
  child: Text(
    'Progress',
    style: AppStyle.text16.copyWith(
      color: AppCustomColor.textPrimary,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Gradient label
```dart
GradientTypography(
  gradient: LinearGradient(colors: AppCustomColor.gradientButton),
  child: Text(
    'Premium',
    style: AppStyle.text14,
  ),
)
```

### Theme-aware color usage
```dart
Container(
  color: AppTheme.surface,
  child: Text(
    'Hello',
    style: AppTheme.textTheme.bodyMedium,
  ),
)
```

## 7. Accessibility and UX Baselines
1. Maintain sufficient contrast for text and interactive controls.
2. Keep tappable targets large enough for mobile interaction.
3. Use semantic labels for non-text interactive UI.
4. Support dynamic text scaling where applicable.

## 8. Do/Don’t
### Do
- Use shared tokens from theme/constants files.
- Reuse existing shared widgets before creating new variants.
- Keep style logic centralized and composable.

### Don’t
- Copy hardcoded hex colors into feature pages without token justification.
- Introduce alternate font families without product approval.
- Bypass `AppStyle` and `AppTheme` for basic typography/theming use cases.
