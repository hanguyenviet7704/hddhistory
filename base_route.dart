import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Defines various types of slide animations for route transitions.
///
/// Each type specifies a direction of movement through [dx] and [dy] coordinates:
/// * [leftToRight]: Slides from left to right (-1, 0)
/// * [rightToLeft]: Slides from right to left (1, 0)
/// * [bottomToTop]: Slides from bottom to top (0, 1)
/// * [topToBottom]: Slides from top to bottom (0, -1)
///
/// The [dx] and [dy] values represent the starting position multipliers for
/// the animation, where:
/// * dx: Horizontal displacement (-1: left, 0: none, 1: right)
/// * dy: Vertical displacement (-1: top, 0: none, 1: bottom)
///
/// [startOffset] provides a convenient way to get the initial position as an [Offset].
enum SlideRouteEffect {
  leftToRight(-1, 0),
  rightToLeft(1, 0),
  bottomToTop(0, 1),
  topToBottom(0, -1);

  final double dx;
  final double dy;

  const SlideRouteEffect(this.dx, this.dy);

  Offset get startOffset => Offset(dx, dy);
}

/// A custom page implementation that provides slide transition animations.
///
/// This class extends [Page] to create custom page transitions with sliding animations.
/// It allows for different slide directions and can be configured as a full-screen dialog.
/// The slide animation duration is fixed at 100 milliseconds.
///
/// See also:
/// * [SlideRouteEffect], which defines the available slide directions
/// * [Page], the base class that this implements
/// * [PageRouteBuilder], used internally to create the route
class AnimatedSlidePage extends MaterialPage {
  /// The direction and type of slide animation to use for the transition
  final SlideRouteEffect slideRouteType;

  /// Whether to treat the route as a full-screen dialog
  final bool fullScreenDialog;

  /// The widget to be displayed in the new route
  final Widget childWidget;

  /// The default duration for the slide animation
  final Duration _defaultDuration = const Duration(milliseconds: 250);

  const AnimatedSlidePage({
    required this.childWidget,
    this.slideRouteType = SlideRouteEffect.rightToLeft,
    this.fullScreenDialog = false,
    super.name,
    LocalKey? pageKey,
  }) : super(key: pageKey, child: childWidget);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (_, animation, __) => CupertinoScaffold(
        topRadius: Radius.circular(24.r),
        body: RepaintBoundary(child: childWidget),
      ),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: slideRouteType.startOffset,
            end: Offset.zero,
          ).animate(animation),
          child: RepaintBoundary(child: child),
        );
      },
      maintainState: true,
      allowSnapshotting: true,
      transitionDuration: _defaultDuration,
      reverseTransitionDuration: _defaultDuration,
      fullscreenDialog: fullScreenDialog,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      opaque: true,
    );
  }
}