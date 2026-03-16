# Update New UX/UI

## Usage

Provide:

- Figma design URL (required)
- Specific component/page to implement (required)

## Agent Questions (Ask First)

1. **Component type**: New page | Update existing page | New widget | Update widget
2. **If updating**: Path to existing file(s) to update
3. **Feature name**: Which feature does this belong to? (e.g., "onboard", "profile", "lesson")
4. **State integration**: Use existing Cubit | Create new Cubit | No state needed
5. **Special requirements**: Animations, gestures, custom layouts?

## Auto-Execute After Questions

### 1. Fetch & Analyze Figma Design

```bash
# Use mcp__figma-dev-mode-mcp-server__get_design_context
```

**Extract automatically:**

- Color palette (hex codes)
- Typography (font sizes, weights, families)
- Spacing values (padding, margins)
- Layout structure (rows, columns, stacks)
- Component hierarchy
- Asset URLs (images, icons)

### 2. Match Design Tokens to Project

**Auto-map to existing:**

- `AppCustomColor.*` constants
- `AppStyle.*` text styles
- `ScreenUtil` responsive values
- Existing widgets from `lib/core/utils/widgets/`

**Flag new tokens needed:**

- New colors not in `AppCustomColor`
- New text styles not in `AppStyle`
- New reusable widgets

### 3. Find Similar Implementations

**Search codebase for:**

- Similar UI patterns
- Same feature area pages/widgets
- Reusable components to leverage

### 4. Generate/Update Files

#### For New Page:

```dart
// lib/src/[feature]/presentation/pages/[page_name]/[page_name].dart
// lib/src/[feature]/presentation/pages/[page_name]/[page_name]_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Auto-import required dependencies

class [PageName]Page extends StatelessWidget {
  const [PageName]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppDI.injector.get<[Feature]Cubit>(),
      child: const [PageName]View(),
    );
  }
}

class [PageName]View extends StatelessWidget {
  const [PageName]View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.[backgroundColor],
      body: SafeArea(
        child: // Generated from Figma structure
      ),
    );
  }
}
```

#### For Widget:

```dart
// lib/src/[feature]/presentation/widgets/[widget_name].dart

class [WidgetName] extends StatelessWidget {
  // Props from Figma
  final String? title;
  final VoidCallback? onTap;

  const [WidgetName]({
    super.key,
    this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Auto-generated from Figma design
      padding: EdgeInsets.symmetric(horizontal: [X].w, vertical: [Y].h),
      decoration: BoxDecoration(
        color: AppCustomColor.[color],
        borderRadius: BorderRadius.circular([radius].r),
      ),
      child: // Generated structure
    );
  }
}
```

### 5. Apply Responsive Design

**Auto-convert all dimensions:**

- Width: `XXpx` → `XX.w`
- Height: `XXpx` → `XX.h`
- Font size: `XXpx` → `XX.sp`
- Radius: `XXpx` → `XX.r`
- Spacing: `XXpx` → `XX.w` or `XX.h`

### 6. Implement Figma Structure

**Auto-generate from Figma layers:**

```dart
// Frame → Container/Column/Row based on layout
// Auto Layout → Column/Row with spacing
// Text → AppText with correct style
// Rectangle → Container with decoration
// Image → CachedNetworkImage/SvgPicture
// Button → GestureDetector/InkWell with Container
```

**Example transformation:**

```
Figma: Frame (Auto Layout Vertical, gap: 16px)
  ↓
Flutter: Column(
  spacing: 16.h,
  children: [...]
)

Figma: Frame (padding: 24px horizontal, 16px vertical)
  ↓
Flutter: Padding(
  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
  child: ...
)
```

### 7. Add Assets (if needed)

```bash
# Download images from Figma
# Save to assets/images/[feature]/
# Update pubspec.yaml if new assets added
```

### 8. Add Routes (if new page)

```dart
// Add to lib/config/routes/app_router.dart
@TypedGoRoute<[Page]Route>(path: '/[path]')
class [Page]Route extends GoRouteData {
  const [Page]Route();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const [Page]Page();
  }
}
```

### 9. Add Localization Keys (if text content)

```bash
# Identify hardcoded text
# Add to appropriate ARB file
# Replace with context.l10n.[key]
```

### 10. Verify & Test

```bash
flutter analyze
# Check hot reload works
# Verify responsive on different screen sizes
```

## Output

```
✅ UI Implementation Complete: [Component Name]

Design Source:
- Figma: [URL]
- Node: [Node ID]

Files Created/Updated:
- [path/to/page_or_widget.dart]
- [path/to/view.dart] (if applicable)

Design Tokens Applied:
- Colors: [list mapped colors]
- Typography: [list text styles used]
- Spacing: [spacing values applied]

New Tokens Added (if any):
- AppCustomColor.[newColor] = Color(0x...)
- AppStyle.[newStyle] = TextStyle(...)

Assets Added (if any):
- assets/images/[feature]/[image].png
- Updated pubspec.yaml

Routes Added (if page):
- Route: /[path]
- Class: [Page]Route

State Integration:
- [Connected to [Feature]Cubit | No state needed]

Responsive:
- ✅ All dimensions converted to responsive units
- ✅ Tested on [screen_sizes]

Next Steps:
1. Test on physical devices
2. Verify animations (if applicable)
3. Add interaction handlers if needed
```

## Design Token Mapping Reference

### Colors

```dart
// Auto-detect and map:
Figma #194185 → AppCustomColor.primary
Figma #FFFFFF → AppCustomColor.surface
Figma #000000 → AppCustomColor.textPrimary
// Create new if not found:
AppCustomColor.[newName] = Color(0x...)
```

### Typography

```dart
// Auto-detect and map:
Figma 32px Bold → AppStyle.textBold32
Figma 16px Regular → AppStyle.textRegular16
// Use closest match or create new
```

### Spacing

```dart
// Common spacing patterns:
8px → 8.w
16px → 16.w
24px → 24.w
32px → 32.w
```

### Layout Patterns

```dart
// Auto Layout Vertical → Column
// Auto Layout Horizontal → Row
// Stack → Stack
// Fixed size → SizedBox
// Fill container → Expanded/Flexible
```

## Common Widget Patterns

### Button from Figma

```dart
GestureDetector(
  onTap: onTap,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: AppCustomColor.primary,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: AppText(
      text,
      style: AppStyle.textBold16.copyWith(color: Colors.white),
    ),
  ),
)
```

### Card from Figma

```dart
Container(
  padding: EdgeInsets.all(16.w),
  decoration: BoxDecoration(
    color: AppCustomColor.surface,
    borderRadius: BorderRadius.circular(16.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8.r,
        offset: Offset(0, 2.h),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Auto-generated content
    ],
  ),
)
```

### List Item from Figma

```dart
ListView.separated(
  padding: EdgeInsets.all(16.w),
  itemCount: items.length,
  separatorBuilder: (_, __) => SizedBox(height: 12.h),
  itemBuilder: (context, index) {
    return // Generated item widget
  },
)
```
