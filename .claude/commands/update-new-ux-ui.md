Description: Implement UI from Figma designs with automatic design token extraction and responsive layout

# Update New UX/UI

## What This Does
Implements Flutter UI from Figma designs by:
- **Extracting design tokens** directly from Figma using MCP
- **Mapping to existing theme** (AppCustomColor, AppStyle)
- **Generating responsive code** with ScreenUtil (.w, .h, .sp)
- **Finding similar UI patterns** in codebase
- **Creating/updating pages and widgets** following project structure
- **Adding routes** and localization keys as needed

**Uses Figma MCP integration** for direct design access without manual exports.

## When to Use
- Implementing new UI screens from Figma
- Updating existing screens with new designs
- Creating reusable widgets from Figma components
- Need design tokens automatically extracted and mapped

**After backend setup** - Use `/setup-new-feature` first for data layer, then this for UI.

## Required Context
**Required:**
- Figma design URL with node ID
- Specific component/page name to implement

**Optional:**
- Screenshot if Figma access is limited
- Existing file path if updating

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. Component type:
   - New page
   - Update existing page
   - New widget
   - Update existing widget

2. If updating: Path to existing file(s)

3. Feature name: Which feature module? (e.g., "profile", "lesson", "onboard")

4. State integration:
   - Use existing Cubit (specify which)
   - Create new Cubit
   - No state needed

5. Special requirements:
   - Animations needed?
   - Gestures (swipe, drag)?
   - Custom layouts?
```

### 2. Extract Figma Design
Uses `mcp__figma-dev-mode-mcp-server__get_design_context` to extract:
- Color palette (hex codes with opacity)
- Typography (font families, sizes, weights, line heights)
- Spacing values (padding, margins, gaps)
- Border radius and borders
- Layout structure (auto layout, constraints)
- Component hierarchy
- Asset URLs (images, icons)

Example extraction:
```json
{
  "colors": {
    "primary": "#194185",
    "surface": "#FFFFFF",
    "background": "#EEF2F6"
  },
  "typography": {
    "title": {
      "family": "Nunito",
      "size": 32,
      "weight": "bold",
      "height": 1.25
    }
  },
  "spacing": {
    "padding": {"horizontal": 80, "vertical": 24},
    "gap": 16
  },
  "layout": {
    "type": "AutoLayout",
    "direction": "vertical",
    "alignment": "center"
  }
}
```

### 3. Map Design Tokens
Spawns **Task agent (Explore)** to:
- Find existing `AppCustomColor` constants
- Find existing `AppStyle` text styles
- Identify which existing tokens match Figma colors
- Find similar UI components for reference

Mapping process:
```
Figma #194185 → Search AppCustomColor
  Found: AppCustomColor.primary = Color(0xFF194185) ✓

Figma 32px Bold Nunito → Search AppStyle
  Found: AppStyle.textBold32 ✓

Figma #FF5733 → Not found
  Create: AppCustomColor.accentOrange = Color(0xFFFF5733) ⚠️
```

### 4. Find Similar UI Patterns
Spawns **Task agent (Explore)** to find:
- Similar pages in same feature module
- Similar widgets (cards, lists, buttons)
- Common layout patterns
- State management integration examples

Example exploration:
```
Task: "Find similar profile pages or settings pages.
      Look for: BlocProvider usage, Scaffold structure,
      responsive layouts, state handling patterns"

Returns: lib/src/profile/presentation/pages/profile_settings/
         - Uses BlocProvider with ProfileCubit
         - SafeArea + SingleChildScrollView pattern
         - Responsive with ScreenUtil
```

### 5. Generate/Update Files
Uses `TodoWrite` to track:
```
☐ Create/update page file
☐ Create/update view file
☐ Map design tokens
☐ Implement responsive layout
☐ Connect state management
☐ Add routes (if new page)
☐ Add localization keys
☐ Validate build
```

#### For New Page
Creates:
```dart
// lib/src/[feature]/presentation/pages/[page_name]/[page_name].dart

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
```

```dart
// lib/src/[feature]/presentation/pages/[page_name]/[page_name]_view.dart

class [PageName]View extends StatelessWidget {
  const [PageName]View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generated from Figma structure
            ],
          ),
        ),
      ),
    );
  }
}
```

#### For Widget
Creates:
```dart
// lib/src/[feature]/presentation/widgets/[widget_name].dart

class [WidgetName] extends StatelessWidget {
  final String? title;
  final VoidCallback? onTap;

  const [WidgetName]({
    super.key,
    this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppCustomColor.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AppText(
          title ?? '',
          style: AppStyle.textBold16,
        ),
      ),
    );
  }
}
```

### 6. Transform Figma to Flutter
Auto-converts Figma layers to Flutter widgets:

**Figma Frame → Flutter Container/Column/Row**
```
Figma: Frame (Auto Layout Vertical, gap: 16px, padding: 24px)
↓
Flutter: Padding(
  padding: EdgeInsets.all(24.w),
  child: Column(
    spacing: 16.h,
    children: [...]
  ),
)
```

**Figma Text → Flutter AppText**
```
Figma: Text (32px, Bold, #194185)
↓
Flutter: AppText(
  'Title',
  style: AppStyle.textBold32.copyWith(
    color: AppCustomColor.primary,
  ),
)
```

**Figma Rectangle → Flutter Container**
```
Figma: Rectangle (fill: #FFFFFF, radius: 20px, shadow)
↓
Flutter: Container(
  decoration: BoxDecoration(
    color: AppCustomColor.surface,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8.r,
        offset: Offset(0, 2.h),
      ),
    ],
  ),
)
```

**Figma Image → Flutter CachedNetworkImage/SvgPicture**
```
Figma: Image (asset URL)
↓
Flutter: CachedNetworkImage(
  imageUrl: assetUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Shimmer.fromColors(...),
)
```

**Figma Button → Flutter GestureDetector + Container**
```
Figma: Button component
↓
Flutter: GestureDetector(
  onTap: onPressed,
  child: Container(
    // Styled from Figma
  ),
)
```

### 7. Apply Responsive Design
Converts all dimensions:
```
Width: 200px → 200.w
Height: 100px → 100.h
Font size: 16px → 16.sp
Radius: 12px → 12.r
Padding: 24px → 24.w or 24.h (based on direction)
```

### 8. Add Routes (if new page)
Updates `lib/config/routes/app_router.dart`:
```dart
@TypedGoRoute<[Page]Route>(path: '/[feature]/[page]')
class [Page]Route extends GoRouteData {
  const [Page]Route();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const [Page]Page();
  }
}
```

### 9. Add Localization Keys
If text content found:
- Identifies hardcoded text
- Creates keys in appropriate ARB file
- Replaces with `context.text.[key]`

Example:
```dart
// Before
Text('Welcome back!')

// After
Text(context.text.welcomeBack)

// Added to lib/config/l10n/arb/app_en.arb:
{
  "welcomeBack": "Welcome back!"
}
```

### 10. Validate Build
Checks:
- ✅ All files compile
- ✅ Hot reload works
- ✅ No missing imports
- ✅ Routes registered (if page)
- ✅ State integration working
- ✅ flutter analyze passes

## Output Format

```
✅ UI Implementation Complete: [Component Name]

🎨 Design Source
- Figma: [URL]
- Node ID: [node_id]
- Design extracted via MCP

🎨 Design Tokens Applied
Colors:
  ✓ AppCustomColor.primary (#194185)
  ✓ AppCustomColor.surface (#FFFFFF)
  ⚠ AppCustomColor.accentOrange (#FF5733) - NEW

Typography:
  ✓ AppStyle.textBold32
  ✓ AppStyle.textRegular16

Spacing:
  - Padding: 24.w horizontal, 16.h vertical
  - Gap: 16.h between elements
  - Border radius: 20.r

📁 Files Created/Updated
✓ lib/src/[feature]/presentation/pages/[page]/[page].dart
✓ lib/src/[feature]/presentation/pages/[page]/[page]_view.dart
✓ lib/config/routes/app_router.dart (route added)
✓ lib/config/l10n/arb/app_en.arb (X keys added)

🔌 State Integration
✓ Connected to [Feature]Cubit
✓ BlocBuilder for reactive updates
✓ Proper error handling

📱 Responsive Design
✓ All dimensions converted to responsive units
✓ Tested layout structure
✓ Works on various screen sizes

🎯 Next Steps
1. Test on physical devices (iOS + Android)
2. Verify animations and gestures
3. Add loading and error states if needed
4. Review with design team for pixel-perfect match
```

## Example Usage

### Example 1: New Profile Page
```
User: /update-new-ux-ui
      Figma: https://figma.com/file/...?node-id=123
      "Profile settings page"

Claude: Questions:
        1. Component type? → New page
        2. Feature name? → profile
        3. State integration? → Use existing ProfileCubit
        4. Special requirements? → None

        [Extracts design from Figma via MCP]
        [Finds similar profile pages for reference]
        [Maps all design tokens]
        [Generates page + view files]
        [Adds route]
        [Validates build]

        ✅ Complete: ProfileSettingsPage
        - 8 design tokens mapped
        - 2 new colors added
        - State connected to ProfileCubit
        - Route: /profile/settings
```

### Example 2: Update Existing Widget
```
User: /update-new-ux-ui
      Figma: https://figma.com/file/...?node-id=456
      "Update lesson card widget with new design"

Claude: Questions:
        1. Component type? → Update existing widget
        2. Existing file? → lib/src/lesson/presentation/widgets/lesson_card.dart
        3. Feature name? → lesson
        4. State integration? → No state needed
        5. Special requirements? → Add shimmer loading animation

        [Extracts new design]
        [Preserves existing props and logic]
        [Updates styling only]
        [Adds shimmer animation]

        ✅ Complete: LessonCard updated
        - Styling updated to match Figma
        - Shimmer animation added
        - Existing functionality preserved
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
    children: [/* content */],
  ),
)
```

### List from Figma
```dart
ListView.separated(
  padding: EdgeInsets.all(16.w),
  itemCount: items.length,
  separatorBuilder: (_, __) => SizedBox(height: 12.h),
  itemBuilder: (context, index) {
    return // Item widget
  },
)
```

## Advanced Features

### Smart Token Creation
When new tokens needed:
```dart
// Suggests addition to lib/config/themes/colors.dart:
class AppCustomColor {
  // Existing colors...

  // ⚠️ NEW - Added from Figma design
  static const Color accentOrange = Color(0xFFFF5733);
  static const Color backgroundGradientStart = Color(0xFFEEF2F6);
}
```

### State Management Integration
Automatically wraps with BlocBuilder:
```dart
BlocBuilder<LessonCubit, LessonState>(
  builder: (context, state) {
    return state.when(
      initial: () => InitialView(),
      loading: () => LoadingShimmer(),
      success: (data) => ContentView(data: data),
      error: (error) => ErrorView(error: error),
    );
  },
)
```

### Asset Management
If images found in Figma:
- Downloads assets
- Saves to `assets/images/[feature]/`
- Updates `pubspec.yaml` if needed
- Uses CachedNetworkImage for remote assets

---

*See CLAUDE.md: UI/UX Patterns for design system guidelines*
*See CLAUDE.md: Responsive Design for ScreenUtil usage*
*See CLAUDE.md: State Management for BLoC integration patterns*
