# Update New UX/UI - General Template

## Overview
This document provides a comprehensive template for updating UI components based on Figma designs. Use this template to systematically approach any UI/UX update, ensuring consistency, quality, and maintainability.

## Pre-Update Checklist

### 1. Design Analysis
- [ ] **Figma URL**: Document the design source
- [ ] **Node ID**: Record the specific component node ID
- [ ] **Design Tokens**: Extract colors, typography, spacing values
- [ ] **Layout Structure**: Analyze component hierarchy and layout
- [ ] **Interactive Elements**: Identify buttons, inputs, gestures
- [ ] **Responsive Behavior**: Note breakpoints and adaptive layouts
- [ ] **Accessibility**: Check contrast ratios and touch targets

### 2. Current Implementation Review
- [ ] **Existing Files**: Identify all related component files
- [ ] **Current Styling**: Document existing colors, fonts, spacing
- [ ] **Dependencies**: Check for related components or utilities
- [ ] **State Management**: Understand any BLoC/Cubit dependencies
- [ ] **Navigation**: Check routing and navigation patterns

## Implementation Process

### Step 1: Design Token Extraction
```dart
// Extract and document all design tokens from Figma
// Colors
const Color primaryColor = Color(0xFF194185);
const Color secondaryColor = Color(0xFF0D121C);
const Color backgroundColor = Color(0xFFEEF2F6);
const Color surfaceColor = Color(0xFFFFFFFF);

// Typography
const TextStyle titleStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 32,
  fontWeight: FontWeight.bold,
  height: 1.25,
);

// Spacing
const double paddingHorizontal = 80.0;
const double paddingVertical = 24.0;
const double borderRadius = 20.0;
```

### Step 2: Component Structure Planning
```dart
// Plan the component hierarchy
Widget build(BuildContext context) {
  return Container(
    // Main container with design tokens
    child: Column(
      children: [
        // Header section
        _buildHeader(),
        // Content section
        _buildContent(),
        // Footer section
        _buildFooter(),
      ],
    ),
  );
}
```

### Step 3: Color Scheme Updates
- [ ] **Primary Colors**: Update main brand colors
- [ ] **Secondary Colors**: Update accent and support colors
- [ ] **Background Colors**: Update surface and background colors
- [ ] **Text Colors**: Update text hierarchy colors
- [ ] **Border Colors**: Update border and divider colors
- [ ] **State Colors**: Update success, error, warning colors

### Step 4: Typography Updates
- [ ] **Font Family**: Ensure consistent font usage
- [ ] **Font Sizes**: Apply responsive font sizing with `.sp`
- [ ] **Font Weights**: Use appropriate weight hierarchy
- [ ] **Line Heights**: Apply proper line spacing
- [ ] **Text Colors**: Match design token colors

### Step 5: Layout and Spacing
- [ ] **Container Sizing**: Use responsive sizing with `.w`, `.h`
- [ ] **Padding/Margins**: Apply consistent spacing system
- [ ] **Border Radius**: Update corner radius values
- [ ] **Flex Layouts**: Implement proper flex distributions
- [ ] **Grid Systems**: Apply consistent grid patterns

### Step 6: Interactive Elements
- [ ] **Buttons**: Update button styles and states
- [ ] **Input Fields**: Update form element styling
- [ ] **Gestures**: Implement tap, swipe, drag interactions
- [ ] **Animations**: Add transition and micro-interactions
- [ ] **Loading States**: Update loading and error states

## File Organization

### Primary Component Files
```
lib/src/presentation/pages/[feature]/widgets/[component]/
├── [component_name].dart          # Main component
├── [component_name]_view.dart     # UI implementation
├── [component_name]_state.dart    # State management
└── widgets/                       # Sub-components
    ├── [sub_component].dart
    └── [another_sub_component].dart
```

### Supporting Files
- **Theme files**: Update colors, typography, spacing
- **Asset files**: Add new images, icons, animations
- **Localization**: Update text strings and translations
- **Routes**: Update navigation if needed

## Implementation Guidelines

### 1. Design System Compliance
```dart
// Use existing design system components
AppText(
  'Text content',
  style: AppStyle.textBold24.copyWith(
    color: AppCustomColor.primary,
  ),
)

// Use existing utilities
Container(
  padding: EdgeInsets.all(16.w),
  margin: EdgeInsets.symmetric(horizontal: 20.w),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12.r),
    color: AppCustomColor.surface,
  ),
)
```

### 2. Responsive Design
```dart
// Always use responsive sizing
Container(
  width: 200.w,           // Width-based responsive
  height: 100.h,          // Height-based responsive
  padding: EdgeInsets.all(16.w),
  child: Text(
    'Content',
    style: TextStyle(fontSize: 16.sp), // Font-based responsive
  ),
)
```

### 3. State Management Integration
```dart
// Integrate with existing BLoC pattern
BlocBuilder<ComponentCubit, ComponentState>(
  builder: (context, state) {
    return state.when(
      initial: () => InitialWidget(),
      loading: () => LoadingWidget(),
      success: (data) => SuccessWidget(data: data),
      error: (error) => ErrorWidget(error: error),
    );
  },
)
```

### 4. Accessibility Considerations
```dart
// Ensure proper accessibility
Semantics(
  label: 'Button description',
  hint: 'Button action hint',
  child: GestureDetector(
    onTap: () => handleTap(),
    child: Container(
      // Ensure minimum touch target size (44x44)
      constraints: BoxConstraints(
        minWidth: 44.w,
        minHeight: 44.h,
      ),
      child: Icon(Icons.add),
    ),
  ),
)
```

## Testing Strategy

### 1. Visual Testing
- [ ] **Design Comparison**: Compare with Figma design pixel-perfect
- [ ] **Color Accuracy**: Verify color values match design tokens
- [ ] **Typography**: Check font sizes, weights, and spacing
- [ ] **Layout**: Verify component positioning and sizing
- [ ] **Responsive**: Test on different screen sizes

### 2. Functional Testing
- [ ] **User Interactions**: Test all buttons, gestures, inputs
- [ ] **State Changes**: Verify state management integration
- [ ] **Navigation**: Test routing and navigation flows
- [ ] **Error Handling**: Test error states and edge cases
- [ ] **Performance**: Check for any performance issues

### 3. Cross-Platform Testing
- [ ] **iOS**: Test on iOS devices and simulators
- [ ] **Android**: Test on Android devices and emulators
- [ ] **Consistency**: Ensure consistent behavior across platforms
- [ ] **Platform-Specific**: Test platform-specific features

## Quality Assurance

### Code Quality
- [ ] **Linting**: Run `flutter analyze` and fix all issues
- [ ] **Formatting**: Apply consistent code formatting
- [ ] **Documentation**: Add proper code documentation
- [ ] **Naming**: Use consistent naming conventions
- [ ] **Structure**: Follow established architectural patterns

### Performance
- [ ] **Build Time**: Ensure no significant build time increase
- [ ] **Runtime**: Check for any performance regressions
- [ ] **Memory**: Monitor memory usage patterns
- [ ] **Battery**: Check for battery drain issues

## Documentation Requirements

### 1. Update Documentation
- [ ] **Component Documentation**: Update component docs
- [ ] **API Documentation**: Document any new APIs
- [ ] **Design System**: Update design system documentation
- [ ] **Changelog**: Add entry to project changelog

### 2. Create Implementation Notes
```markdown
## [Component Name] Update

### Changes Made
- Updated color scheme from [old] to [new]
- Modified layout structure for better UX
- Added new interactive elements
- Improved accessibility features

### Files Modified
- `lib/src/presentation/.../[component].dart`
- `lib/config/themes/colors.dart`
- `assets/...` (if new assets added)

### Design Reference
- Figma URL: [design_url]
- Node ID: [node_id]

### Testing Notes
- Tested on iOS and Android
- Verified responsive behavior
- Confirmed accessibility compliance
```

## Common Patterns and Solutions

### 1. Color Theme Updates
```dart
// Create color constants for new theme
class NewThemeColors {
  static const Color primary = Color(0xFF194185);
  static const Color secondary = Color(0xFF0D121C);
  static const Color background = Color(0xFFEEF2F6);
  static const Color surface = Color(0xFFFFFFFF);
}

// Apply consistently across components
Container(
  color: NewThemeColors.background,
  child: Text(
    'Content',
    style: TextStyle(color: NewThemeColors.primary),
  ),
)
```

### 2. Layout Structure Updates
```dart
// Use consistent layout patterns
class ComponentLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildFooter(),
        ],
      ),
    );
  }
}
```

### 3. Interactive Element Updates
```dart
// Consistent button styling
class ThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCustomColor.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: AppText(
          text,
          style: AppStyle.textBold16.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

## Troubleshooting Common Issues

### 1. Layout Issues
- **Problem**: Components not positioning correctly
- **Solution**: Check flex properties and container constraints
- **Prevention**: Use consistent layout patterns

### 2. Color Issues
- **Problem**: Colors not matching design
- **Solution**: Verify color values and opacity settings
- **Prevention**: Use design system color constants

### 3. Responsive Issues
- **Problem**: Components not scaling properly
- **Solution**: Use `.w`, `.h`, `.sp` extensions consistently
- **Prevention**: Test on multiple screen sizes

### 4. Performance Issues
- **Problem**: UI updates causing performance problems
- **Solution**: Optimize widget rebuilds and state management
- **Prevention**: Use proper BLoC patterns and const constructors

## Best Practices

### 1. Design System First
- Always check existing design system components before creating new ones
- Use established color, typography, and spacing tokens
- Maintain consistency with existing patterns

### 2. Mobile-First Approach
- Design for mobile screens first, then adapt for larger screens
- Ensure touch targets are at least 44x44 logical pixels
- Test on actual devices, not just simulators

### 3. Accessibility First
- Ensure proper contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Provide semantic labels for screen readers
- Test with accessibility tools

### 4. Performance Conscious
- Use const constructors where possible
- Minimize widget rebuilds
- Optimize image and asset loading

### 5. Documentation Driven
- Document all design decisions
- Update design system documentation
- Provide clear implementation notes

## Future Maintenance

### Regular Updates
- Review and update design tokens quarterly
- Audit component consistency monthly
- Update documentation with each release

### Design System Evolution
- Track design system usage across components
- Identify patterns for new design system additions
- Maintain backward compatibility when possible

### Performance Monitoring
- Monitor app performance metrics
- Track user experience improvements
- Optimize based on real-world usage data

---

## Quick Reference

### Essential Commands
```bash
# Analyze code quality
flutter analyze

# Run tests
flutter test

# Check for unused imports
dart fix --apply

# Format code
dart format .
```

### Key Files to Check
- `lib/config/themes/colors.dart` - Color definitions
- `lib/config/themes/text_theme.dart` - Typography
- `lib/core/utils/` - Utility components
- `assets/` - Images, icons, fonts

### Design System Components
- `AppText` - Text component
- `AppButton` - Button component
- `AppCustomColor` - Color constants
- `AppStyle` - Text styles
- `ScreenUtil` - Responsive utilities

This template ensures consistent, high-quality UI updates while maintaining design system integrity and code quality standards.