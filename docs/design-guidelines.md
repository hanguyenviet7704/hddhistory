# Design Guidelines

**Last Updated:** Jan 22, 2026
**Applies To:** All UI components in Meup Flutter app

---

## 1. Overview

Meup uses a modern, responsive design system built on **Material Design 3**, **flutter_screenutil** for responsive sizing, and a comprehensive component library. All UI components live in `lib/core/utils/` organized by category, with factory constructors for variant patterns.

**Key Principles:**
- Responsive-first: Use `flutter_screenutil` (.w, .h, .sp) for all dimensions
- Semantic colors: Brand-aware color palette with light/dark support
- Composition: Wrap/delegate behavior; no large monolithic widgets
- Factory constructors: `AppButton.primary()`, `AppButton.secondary()` for variants

---

## 2. Color System

### Brand Colors
| Color | Hex Value | Usage |
|-------|-----------|-------|
| Brand Primary | `#554FF0` | Buttons, accents, primary actions |
| Brand Primary 50 | `#EBEAVD` | Light backgrounds for brand elements |
| Brand Primary 700 | `#362F82` | Dark text/icons for brand |
| Brand Primary 900 | `#151123` | Very dark backgrounds |

### Semantic Text Colors
| Name | Hex Value | Usage |
|------|-----------|-------|
| Text Primary | `#0D121C` | Main body text |
| Text Secondary | `#364152` | Secondary/supporting text |
| Text Tertiary | `#7F8EA4` | Disabled/muted text |
| Text Quaternary | `#AAB8CD` | Borders/separators |
| Text Brand | `#110751` | Brand-colored text |
| Text White | `#FFFFFF` | Text on dark backgrounds |

### Surface & Background Colors
| Name | Hex Value | Usage |
|------|-----------|-------|
| Background White | `#FFFFFF` | Default surfaces |
| Background Gray | `#F5F7FB` | Secondary surfaces |
| Background Error | `#FDEBE7` | Error backgrounds |
| Background Success | `#EAFFEF` | Success backgrounds |
| Background Brand Soft | `#F2F1FE` | Soft brand overlays |
| Border Default | `#EBF0F7` | Primary borders |
| Border Secondary | `#E3E8EF` | Secondary borders |

### Gradient Definitions
```dart
// In AppCustomColor mixin (lib/config/themes/colors.dart)

// Gradient Button: Orange/Red warm gradient
static const List<Color> gradientButton = [
  Color(0xFFE86423), Color(0xFFF38421), Color(0xFFF7704B),
  Color(0xFFF86959), Color(0xFFFA4A92),
];

// Gradient Background: Fiery sunset gradient
static const List<Color> gradientBackground = [
  Color(0xFFE35524), Color(0xFFF58921), Color(0xFFF86463),
  Color(0xFFFF15F0),
];

// Gradient Avatar Border: Rainbow border
static const List<Color> gradientAvatarBorder = [
  Color(0xFFD02027), Color(0xFFF58822), Color(0xFFF95C70),
  Color(0xFFFF15F0),
];

// Gradient Roleplay: 9-color vibrant palette
static const List<Color> gradientRoleplay = [
  Color(0xFFE3E7EF), Color(0xFFFFA9A8), Color(0xFFF8A1DC),
  Color(0xFFE6A5F2), Color(0xFFBEB8FA), Color(0xFF93CEF8),
  Color(0xFF79E2D7), Color(0xFF98DC98), Color(0xFFECB984),
];
```

### Accessing Colors in Code
```dart
// Direct mixin access
import 'package:config/themes/themes.dart';

Color brandColor = AppCustomColor.brandPrimary;
Color errorBg = AppCustomColor.backgroundError;
List<Color> gradient = AppCustomColor.gradientButton;

// Material theme colors (light/dark aware)
Color primary = context.appTheme.primaryColor;
Color onPrimary = context.appTheme.onPrimary;
Color error = context.appTheme.error;
```

---

## 3. Typography

### Font Family
- **Font:** Mulish
- **Weights:** Normal (400), Bold (700)
- **Line Height:** 1.5 (default)

### Size Scale
Complete 27-size scale from 6sp to 56sp:

| Style | Size | Regular | Bold |
|-------|------|---------|------|
| Text 6 | 6sp | `AppStyle.text6` | `AppStyle.textBold6` |
| Text 8 | 8sp | `AppStyle.text8` | `AppStyle.textBold8` |
| Text 10 | 10sp | `AppStyle.text10` | `AppStyle.textBold10` |
| Text 12 | 12sp | `AppStyle.text12` | `AppStyle.textBold12` |
| Text 14 | 14sp | `AppStyle.text14` | `AppStyle.textBold14` |
| Text 16 | 16sp | `AppStyle.text16` | `AppStyle.textBold16` |
| Text 18 | 18sp | `AppStyle.text18` | `AppStyle.textBold18` |
| Text 20 | 20sp | `AppStyle.text20` | `AppStyle.textBold20` |
| Text 24 | 24sp | `AppStyle.text24` | `AppStyle.textBold24` |
| Text 28 | 28sp | `AppStyle.text28` | `AppStyle.textBold28` |
| Text 32 | 32sp | `AppStyle.text32` | `AppStyle.textBold32` |
| Text 36 | 36sp | `AppStyle.text36` | `AppStyle.textBold36` |
| Text 40 | 40sp | `AppStyle.text40` | `AppStyle.textBold40` |
| Text 48 | 48sp | `AppStyle.text48` | `AppStyle.textBold48` |
| Text 56 | 56sp | `AppStyle.text56` | `AppStyle.textBold56` |

### Usage Examples
```dart
// Regular text
AppText(
  'Hello World',
  style: AppStyle.text16,
);

// Bold text
AppText(
  'Important',
  style: AppStyle.textBold20,
);

// Custom styling
AppText(
  'Colored text',
  style: AppStyle.text14.copyWith(color: Colors.red),
);
```

---

## 4. Responsive Design

### flutter_screenutil System
Meup uses `flutter_screenutil` for consistent sizing across devices. All dimensions use proportional extensions:

| Extension | Purpose | Example |
|-----------|---------|---------|
| `.w` | Width scale | `20.w` = 20 DP width-proportional |
| `.h` | Height scale | `30.h` = 30 DP height-proportional |
| `.sp` | Font size scale | `14.sp` = 14 SP font-proportional |
| `.r` | Border radius | `8.r` = 8 DP radius-proportional |

### Sizing Conventions
```dart
// Padding & margins (use .w/.h for proportional scaling)
EdgeInsets.all(16.w)
EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h)

// Border radius
BorderRadius.circular(12.r)
BorderRadius.only(
  topLeft: Radius.circular(16.r),
  topRight: Radius.circular(16.r),
)

// Font sizes (always use .sp)
TextStyle(fontSize: 14.sp, height: 1.5.h)

// Container dimensions
Container(
  width: 100.w,
  height: 100.h,
  child: ...,
)
```

### Design Breakpoints
- **Phone:** <600dp width
- **Tablet:** 600-900dp width
- **Desktop:** >900dp width

Use `MediaQuery.of(context).size.width` for responsive conditionals if needed beyond flutter_screenutil.

---

## 5. Component Library

### Organization Structure
```
lib/core/utils/
├── utils.dart              # Main library file (part of 'utils.dart')
├── animation/              # Animations (FadeUp, SlideTransition, ExpandContainer)
├── button/                 # Buttons (AppButton, GradientButton, CTAButton)
├── decoration/             # Decorative elements (GradientIndicator)
├── images/                 # Image handling (CacheImage, NetworkAvatar, ContainerImage)
├── input/                  # Form inputs (TextField, Dropdown, Range, SelectSearchButton)
├── layouts/                # Page layouts (LandingLayout, ScaffoldLayout, ErrorLayout)
├── navbar/                 # Navigation (BottomNav, BottomNavCurve, NavBarItems)
├── overlay/                # Dialogs/overlays (Dialog, BottomSheet, LoadingDialog)
├── select/                 # Selection (CheckBox, RadioButton)
├── sliver/                 # Sliver widgets (SliverAppBar, SliverChild)
├── text/                   # Text variants (AppText, HighlightText, GradientText)
├── timer/                  # Timers (CountDown, StopWatch)
├── video/                  # Video (PreloadView)
├── webview/                # WebView wrapper
└── wrap/                   # Wrappers (GradientBoxBorder, SafeBody, Unfocused)
```

### Button Components

**Factory Constructor Pattern:**
```dart
// Primary (brand) button
AppButton.primary(
  onPressed: () => {},
  child: Text('Save'),
)

// Secondary button (alternative style)
AppButton.secondary(
  onPressed: () => {},
  child: Text('Cancel'),
)

// Gradient button
GradientButton(
  gradient: LinearGradient(colors: AppCustomColor.gradientButton),
  onPressed: () => {},
  child: Text('Action'),
)

// CTA button (call-to-action, typically full-width)
CTAButton(
  title: 'Continue',
  onPressed: () => {},
)
```

**Custom Styling:**
```dart
AppButton(
  onPressed: () => {},
  borderRadius: BorderRadius.circular(8.r),
  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
  height: 48.h,
  fullWidthBtn: true,
  child: Text('Full Width Button'),
)
```

### Text Components
```dart
// Simple text
AppText('Regular text', style: AppStyle.text16)

// With tooltip (if text is truncated)
AppText(
  'Long text...',
  style: AppStyle.text14,
  enableTooltip: true,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)

// Gradient text
GradientText(
  'Colorful',
  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
  style: AppStyle.textBold24,
)

// Highlighted text (marks specific words)
HighlightText(
  text: 'This is highlighted text',
  highlights: ['highlighted'],
  highlightStyle: AppStyle.textBold14.copyWith(color: Colors.red),
)

// Icon + text
IconText(
  icon: Icons.star,
  text: 'Rating',
  style: AppStyle.text14,
)
```

### Image Components
```dart
// Network image with caching
CacheImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 100.w,
  height: 100.h,
)

// Avatar from network
NetworkAvatar(
  imageUrl: userProfileUrl,
  size: 64.w,
  borderGradient: LinearGradient(
    colors: AppCustomColor.gradientAvatarBorder,
  ),
)

// Container with image fit
ContainerImage(
  imageUrl: backgroundUrl,
  fit: BoxFit.cover,
)

// Image full-screen viewer
ImageViewPage(
  imageUrl: fullScreenUrl,
)
```

### Form Inputs
```dart
// Text field
AppTextField(
  label: 'Email',
  hint: 'Enter email',
  onChanged: (value) => {},
)

// Dropdown select
AppDropdown(
  items: ['Option 1', 'Option 2', 'Option 3'],
  onSelected: (value) => {},
)

// Range slider
AppRange(
  min: 0,
  max: 100,
  value: 50,
  onChanged: (value) => {},
)

// Search select button
SelectSearchButton(
  items: searchItems,
  onSelected: (item) => {},
)
```

### Overlays & Dialogs
```dart
// Simple dialog
showAppDialog(
  context,
  title: 'Confirm',
  message: 'Are you sure?',
  onConfirm: () => Navigator.pop(context),
)

// Yes/No dialog
showYesNoDialog(
  context,
  title: 'Delete?',
  onYes: () => {},
  onNo: () => {},
)

// Loading dialog
showLoadingDialog(context)

// Bottom sheet
showAppBottomSheet(
  context,
  child: YourContent(),
)

// Message/Toast
context.showMessage('Success!', type: MessageType.success)
```

### Layout Wrappers
```dart
// Safe area body wrapper
SafeBody(
  child: Column(...),
)

// Gradient box with border
Container(
  decoration: BoxDecoration(
    border: GradientBoxBorder(
      gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
      width: 2,
    ),
  ),
  child: YourContent(),
)

// Landing page layout
LandingLayout(
  child: YourContent(),
)

// Error state layout
ErrorLayout(
  message: 'Something went wrong',
  onRetry: () => {},
)
```

---

## 6. Theming: Light/Dark Mode

### Theme Access Patterns
```dart
// Via BuildContext extension
Color primaryColor = context.appTheme.primaryColor;
Color onPrimary = context.appTheme.onPrimary;
TextTheme textTheme = context.appTheme.textTheme;

// Direct mixin access (when context unavailable)
Color brandColor = AppCustomColor.brandPrimary;
Color surface = AppTheme.surface;

// Material color scheme
ColorScheme scheme = Theme.of(context).colorScheme;
```

### Light/Dark Theme Implementation
Meup supports Material 3 light and dark themes via `LightTheme` and `DarkTheme` mixins in `lib/config/themes/material_theme.dart`. Theme switching managed by `ThemeCubit`.

**Theme switching:**
```dart
// In your Cubit/BLoC
context.read<ThemeCubit>().toggleTheme();

// Or set specific theme
context.read<ThemeCubit>().setTheme(ThemeMode.dark);
```

### Material Customizations
Both light and dark themes customize:
- Primary/secondary color schemes
- App bar styling
- Button styling
- Input decoration
- Card styling
- Dialog styling
- Bottom sheet styling
- Navigation styling

See `lib/config/themes/material_theme.dart` for complete Material widget theme definitions.

---

## 7. Best Practices

### DO
- Use `AppButton.primary()` factory for brand buttons
- Apply `.w`, `.h`, `.sp` to ALL dimensions (no hardcoded pixels)
- Access colors via `AppCustomColor` or `context.appTheme`
- Compose widgets: split large ones into smaller parts
- Use `part of '../utils.dart'` for component files
- Keep components under 200 lines; extract logic to separate files
- Use `AppText` for all text rendering
- Verify text styles exist in `AppStyle` before custom styling

### DON'T
- Hardcode pixel values (use flutter_screenutil extensions)
- Import data layer types in presentation
- Create monolithic 400+ line widgets
- Use `Text()` directly (use `AppText`)
- Define colors inline (reference `AppCustomColor`)
- Ignore loading/error states in data fetching
- Skip responsive testing on multiple device sizes
- Forget to add null safety checks with `?.` operator

### Accessibility
- Always provide `semanticLabel` for icons
- Use sufficient color contrast ratios (WCAG AA minimum)
- Ensure touch targets ≥48.h height
- Test with screen readers (esp. Arabic/RTL)
- Avoid color-only differentiation; use icons/text

### Performance
- Use `const` constructors everywhere possible
- Cache network images via `CacheImage`
- Lazy-load off-screen content with `ListView.builder`
- Avoid rebuilds: use `const` widgets, memoization
- Profile with Flutter DevTools before optimization

---

## 8. Code Examples

### Complete Button Implementation
```dart
// Usage
AppButton.primary(
  onPressed: () => cubit.submitForm(),
  child: AppText(
    'Submit',
    style: AppStyle.textBold16.copyWith(
      color: AppCustomColor.textWhite,
    ),
  ),
)
```

### Complete Form with Validation
```dart
Form(
  key: formKey,
  child: Column(
    children: [
      AppTextField(
        label: 'Email',
        hint: 'example@email.com',
        validator: (value) {
          if (value?.isEmpty == true) return 'Required';
          if (!value!.contains('@')) return 'Invalid email';
          return null;
        },
        onChanged: (value) => emailState = value,
      ),
      SizedBox(height: 16.h),
      AppTextField(
        label: 'Password',
        obscureText: true,
        validator: (value) {
          if (value?.isEmpty == true) return 'Required';
          if (value!.length < 6) return 'Min 6 chars';
          return null;
        },
      ),
      SizedBox(height: 24.h),
      AppButton.primary(
        fullWidthBtn: true,
        onPressed: () {
          if (formKey.currentState!.validate()) {
            // Submit
          }
        },
        child: AppText('Sign Up', style: AppStyle.textBold16),
      ),
    ],
  ),
)
```

### Responsive Layout Example
```dart
class ResponsiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12.w : 20.w),
      child: Column(
        children: [
          AppText(
            'Title',
            style: isSmall ? AppStyle.text18 : AppStyle.text24,
          ),
          SizedBox(height: 16.h),
          AppButton.primary(
            fullWidthBtn: true,
            onPressed: () => {},
            child: AppText('Action', style: AppStyle.textBold16),
          ),
        ],
      ),
    );
  }
}
```

---

## Related Documentation
- [Code Standards](./code-standards.md) - Architecture & state management
- [System Architecture](./system-architecture.md) - App layers & structure
- [API Integration Guide](./api-integration-guide.md) - Data fetching patterns
