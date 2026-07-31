part of '../../../../lesson.dart';

class LessonContentCard extends StatelessWidget {
  const LessonContentCard({
    super.key,
    required this.child,
    this.footer,
    this.padding,
    this.minHeight,
    this.frosted = false,
  });

  final Widget child;

  /// Pinned to the BOTTOM of the card, with [child] taking the space above it
  /// and scrolling if it needs to — the design's `flex:1` content block over a
  /// fixed action row. An exercise card passes its Check button / verdict here so
  /// it sits at the card's bottom edge instead of trailing the last option.
  ///
  /// Only pinned when the card has a bounded height to pin against; in an
  /// unbounded context (roleplay, review lists) it simply follows [child].
  final Widget? footer;

  final EdgeInsetsGeometry? padding;
  final double? minHeight;

  /// Opt into the frosted-glass treatment over a custom study background (the
  /// theory content card sets this). Other content cards stay solid white.
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final effectiveMinHeight = minHeight ?? LessonCardMinHeightScope.maybeOf(context);

    // ThemedGlassCard renders an identical opaque white card on the Default
    // preset (same colour/radius/shadow as before) and a frosted-glass panel
    // over a custom study background (design item 12) — width/min-height are
    // applied here since ThemedGlassCard itself doesn't take size constraints.
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: effectiveMinHeight == null ? const BoxConstraints() : BoxConstraints(minHeight: effectiveMinHeight),
        child: ThemedGlassCard(
          // Keypoint v2 card geometry: 22pt corners and a slightly deeper
          // bottom inset, so the Check/verdict block inside an exercise card
          // clears the card edge without an extra spacer.
          padding: padding ?? EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
          radius: 22,
          frosted: frosted,
          // Uses the shared frosted-glass default (strong blur + ~0.7 white) so
          // every themed card looks consistent across the app.
          shadow: [
            BoxShadow(
              color: AppCustomColor.neutral01.withValues(alpha: 0.06),
              blurRadius: 22.r,
              offset: Offset(0, 8.h),
            ),
          ],
          child: _CardContentLayout(footer: footer, child: child),
        ),
      ),
    );
  }
}

/// Lays the card's contents out the way the design does: the content block takes
/// the height that is left and scrolls if it overflows, and [footer] stays pinned
/// to the card's bottom edge.
///
/// Both behaviours need a bounded height, so both are conditional on one:
///
/// - **Scrolling the content** is what keeps a keypoint card a fixed panel
///   (`height: 100%` in the design) with only its contents moving. Previously the
///   whole card sat in a scroll view, so a card taller than its page slid under
///   the pager's clip — taking its rounded corners and top padding with it and
///   slicing the first line of text in half.
/// - **Pinning the footer** is the design's `flex:1; min-height:14px` spacer
///   above the Check button. `Expanded` needs a bounded height to expand into, so
///   in an unbounded context the footer just follows the content instead.
///
/// The unbounded case is a real one, not defensive coding: these same cards are
/// rendered inside roleplay columns and review lists.
class _CardContentLayout extends StatelessWidget {
  const _CardContentLayout({required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // Non-null only on the live theory card, which lets narration scroll the
    // text as it reads it (see [NarrationAutoScroll]). Everywhere else the
    // scroller keeps its own implicit controller and stays fully manual.
    final narrationController = NarrationScrollScope.maybeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pinnedFooter = footer;

        if (!constraints.hasBoundedHeight) {
          if (pinnedFooter == null) return child;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [child, pinnedFooter],
          );
        }

        if (pinnedFooter == null) return SingleChildScrollView(controller: narrationController, child: child);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SingleChildScrollView(controller: narrationController, child: child)),
            pinnedFooter,
          ],
        );
      },
    );
  }
}

class LessonCardMinHeightScope extends InheritedWidget {
  const LessonCardMinHeightScope({
    super.key,
    required this.minHeight,
    required super.child,
  });

  final double minHeight;

  static double? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LessonCardMinHeightScope>()?.minHeight;
  }

  @override
  bool updateShouldNotify(LessonCardMinHeightScope oldWidget) => minHeight != oldWidget.minHeight;
}
