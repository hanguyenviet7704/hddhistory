part of '../routes.dart';

@immutable
abstract class BaseRouteData extends GoRouteData {
  const BaseRouteData();
  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;
}

/// Enum defining different types of route transitions
enum RouteTransitionType {
  fade,
  slide,
  scale,
  rotation,
  fadeThrough, // Material Design fade through
  sharedAxisX, // Material Design shared axis horizontal
  sharedAxisY, // Material Design shared axis vertical
  sharedAxisZ, // Material Design shared axis depth
  zoom, // Zoom in/out from center
  slideScale, // Combined slide and scale
  fadeSlide, // Combined fade and slide
  flip, // 3D flip animation
  size, // Size transition
  custom,
}

/// Configuration for route transitions
class RouteTransitionConfig {
  final RouteTransitionType type;
  final Duration duration;
  final Curve curve;
  final SlideRouteEffect? slideEffect;
  final double? minScale;
  final Alignment? scaleAlignment;
  final double? rotationAngle;
  final double? maxScale;
  final Offset? slideOffset;
  final Axis? flipAxis;
  final double? perspectiveValue;

  const RouteTransitionConfig({
    this.type = RouteTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCirc,
    this.slideEffect,
    this.minScale = 0.85,
    this.scaleAlignment = Alignment.center,
    this.rotationAngle = 0.5,
    this.maxScale = 1.1,
    this.slideOffset,
    this.flipAxis = Axis.horizontal,
    this.perspectiveValue = 0.003,
  });

  /// Preset configurations for common transitions
  static const RouteTransitionConfig fade = RouteTransitionConfig();

  static const RouteTransitionConfig slideFromRight = RouteTransitionConfig(
    type: RouteTransitionType.slide,
    slideEffect: SlideRouteEffect.rightToLeft,
  );

  static const RouteTransitionConfig slideFromLeft = RouteTransitionConfig(
    type: RouteTransitionType.slide,
    slideEffect: SlideRouteEffect.leftToRight,
  );

  static const RouteTransitionConfig slideFromBottom = RouteTransitionConfig(
    type: RouteTransitionType.slide,
    slideEffect: SlideRouteEffect.bottomToTop,
  );

  static const RouteTransitionConfig slideFromTop = RouteTransitionConfig(
    type: RouteTransitionType.slide,
    slideEffect: SlideRouteEffect.topToBottom,
  );

  static const RouteTransitionConfig scale = RouteTransitionConfig(
    type: RouteTransitionType.scale,
  );

  static const RouteTransitionConfig rotation = RouteTransitionConfig(
    type: RouteTransitionType.rotation,
  );

  // Material Design transitions
  static const RouteTransitionConfig fadeThrough = RouteTransitionConfig(
    type: RouteTransitionType.fadeThrough,
    duration: Duration(milliseconds: 300),
  );

  static const RouteTransitionConfig sharedAxisX = RouteTransitionConfig(
    type: RouteTransitionType.sharedAxisX,
    duration: Duration(milliseconds: 300),
  );

  static const RouteTransitionConfig sharedAxisY = RouteTransitionConfig(
    type: RouteTransitionType.sharedAxisY,
    duration: Duration(milliseconds: 300),
  );

  static const RouteTransitionConfig sharedAxisZ = RouteTransitionConfig(
    type: RouteTransitionType.sharedAxisZ,
    duration: Duration(milliseconds: 300),
  );

  // Combined transitions
  static const RouteTransitionConfig zoom = RouteTransitionConfig(
    type: RouteTransitionType.zoom,
    minScale: 0.8,
    maxScale: 1.2,
    curve: Curves.easeInOutCubic,
  );

  static const RouteTransitionConfig slideScale = RouteTransitionConfig(
    type: RouteTransitionType.slideScale,
    slideEffect: SlideRouteEffect.rightToLeft,
    minScale: 0.9,
  );

  static const RouteTransitionConfig fadeSlide = RouteTransitionConfig(
    type: RouteTransitionType.fadeSlide,
    slideEffect: SlideRouteEffect.rightToLeft,
    duration: Duration(milliseconds: 350),
  );

  // 3D transitions
  static const RouteTransitionConfig flipHorizontal = RouteTransitionConfig(
    type: RouteTransitionType.flip,
    flipAxis: Axis.horizontal,
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOutBack,
  );

  static const RouteTransitionConfig flipVertical = RouteTransitionConfig(
    type: RouteTransitionType.flip,
    flipAxis: Axis.vertical,
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOutBack,
  );

  // Size transition
  static const RouteTransitionConfig sizeTransition = RouteTransitionConfig(
    type: RouteTransitionType.size,
    scaleAlignment: Alignment.center,
  );
}

/// The app's transitions, in one place.
///
/// Lifted out of [BaseTransitionRouteData] unchanged so an IMPERATIVE push can
/// wear the same animation as a typed route — see [appPageRoute]. A page pushed
/// with a plain `MaterialPageRoute` slides in from the right on iOS, which is
/// the platform's transition, not this app's, and the reader notices the one
/// screen that moves differently from every other.
Widget buildRouteTransition(
  RouteTransitionConfig config,
  Animation<double> animation,
  Widget child, {
  /// The typed-route path passes its own overridable builder; an imperative push
  /// has none, so [RouteTransitionType.custom] falls back to a fade.
  Widget Function(Animation<double> animation, Widget child)? onCustom,
}) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: config.curve,
  );

  switch (config.type) {
    case RouteTransitionType.fade:
      return FadeTransition(
        opacity: curvedAnimation,
        child: child,
      );

    case RouteTransitionType.slide:
      final slideEffect = config.slideEffect ?? SlideRouteEffect.rightToLeft;
      return SlideTransition(
        position: Tween<Offset>(
          begin: slideEffect.startOffset,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case RouteTransitionType.scale:
      return ScaleTransition(
        scale: Tween<double>(
          begin: config.minScale ?? 0.85,
          end: 1.0,
        ).animate(curvedAnimation),
        alignment: config.scaleAlignment ?? Alignment.center,
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.rotation:
      return RotationTransition(
        turns: Tween<double>(
          begin: config.rotationAngle ?? 0.5,
          end: 0.0,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.fadeThrough:
      // Material Design fade through pattern
      return FadeTransition(
        opacity:
            Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
              ),
            ),
        child: child,
      );

    case RouteTransitionType.sharedAxisX:
      // Material Design shared axis horizontal
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.sharedAxisY:
      // Material Design shared axis vertical
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.sharedAxisZ:
      // Material Design shared axis depth (scale with fade)
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.zoom:
      // Zoom in/out animation
      final scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: config.minScale ?? 0.8,
            end: config.maxScale ?? 1.1,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: config.maxScale ?? 1.1,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
      ]);

      return ScaleTransition(
        scale: scale.animate(animation),
        alignment: config.scaleAlignment ?? Alignment.center,
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.slideScale:
      // Combined slide and scale effect
      final slideEffect = config.slideEffect ?? SlideRouteEffect.rightToLeft;
      return SlideTransition(
        position: Tween<Offset>(
          begin: slideEffect.startOffset,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: config.minScale ?? 0.9,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        ),
      );

    case RouteTransitionType.fadeSlide:
      // Smooth fade with slight slide
      final slideEffect = config.slideEffect ?? SlideRouteEffect.rightToLeft;
      final offset = slideEffect.startOffset * 0.3; // Reduced slide distance

      return SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );

    case RouteTransitionType.flip:
      // 3D flip animation
      final axis = config.flipAxis ?? Axis.horizontal;
      final isHorizontal = axis == Axis.horizontal;

      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, child) {
          final value = curvedAnimation.value;
          final angle = (1 - value) * 3.14159; // PI radians

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, config.perspectiveValue ?? 0.003)
              ..rotateY(isHorizontal ? angle : 0)
              ..rotateX(isHorizontal ? 0 : angle),
            alignment: Alignment.center,
            child: value < 0.5 ? Opacity(opacity: 1 - (value * 2), child: child) : Opacity(opacity: (value - 0.5) * 2, child: child),
          );
        },
        child: child,
      );

    case RouteTransitionType.size:
      // Size transition (growing effect)
      return Align(
        alignment: config.scaleAlignment ?? Alignment.center,
        child: SizeTransition(
          sizeFactor: curvedAnimation,
          axis: Axis.vertical,
          alignment: Alignment(0.0, -1.0),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        ),
      );

    case RouteTransitionType.custom:
      return onCustom == null
          ? FadeTransition(opacity: curvedAnimation, child: child)
          : onCustom(curvedAnimation, child);
  }
}

/// A page pushed IMPERATIVELY — a root push that sits ABOVE the shell — wearing
/// the app's own transition.
///
/// The typed routes get theirs from [BaseTransitionRouteData]; a screen opened
/// with `Navigator.push` has no route data to carry one, and reaching for
/// `MaterialPageRoute` there is how "Khóa học của tôi" ended up sliding in from
/// the right while its neighbours in the same Profile list scaled up.
///
/// Deliberately UNNAMED: the root observer feeds `route.settings.name` to the
/// screen-view tracker and to `PageCubit.currentRouteName`, so naming it here
/// would start emitting an analytics event that never existed and write a route
/// name nothing else knows about.
PageRoute<T> appPageRoute<T>({
  required WidgetBuilder builder,
  RouteTransitionConfig config = RouteTransitionConfig.scale,
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: config.duration,
    reverseTransitionDuration: config.duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        buildRouteTransition(config, animation, child),
  );
}

abstract class BaseTransitionRouteData extends GoRouteData {
  const BaseTransitionRouteData();

  /// Override this to provide custom transition configuration
  RouteTransitionConfig get transitionConfig => const RouteTransitionConfig();

  @override
  CustomTransitionPage<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage(
      name: state.name,
      key: state.pageKey,
      child: buildPageWidget(context, state),
      transitionDuration: transitionConfig.duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(animation, child);
      },
    );
  }

  Widget _buildTransition(Animation<double> animation, Widget child) =>
      buildRouteTransition(
        transitionConfig,
        animation,
        child,
        onCustom: buildCustomTransition,
      );

  /// Override this method to provide completely custom transitions
  Widget buildCustomTransition(Animation<double> animation, Widget child) {
    // Default to fade if custom not implemented
    return FadeTransition(opacity: animation, child: child);
  }

  Widget buildPageWidget(BuildContext context, GoRouterState state);
}

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
  topToBottom(0, -1)
  ;

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
      pageBuilder: (_, animation, _) => Scaffold(
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

class ModalSheetPage<T> extends Page<T> {
  const ModalSheetPage({
    required this.builder,
    this.barrierColor,
    this.backgroundColor,
    this.topRadius,
    this.transitionBackgroundColor,
    this.previousRouteAnimationCurve,
    this.boxShadow,
    this.enableDrag = true,
    this.expanded = false,
    this.bounce = false,
    this.isDismissible = true,
    this.duration,
    this.containerBuilder,
    this.closeProgressThreshold,
    this.useCupertinoStyle = true,
    super.key,
    super.name,
  });

  final WidgetBuilder builder;
  final Color? barrierColor;
  final Color? backgroundColor;
  final Radius? topRadius;
  final Color? transitionBackgroundColor;
  final Curve? previousRouteAnimationCurve;
  final BoxShadow? boxShadow;
  final bool enableDrag;
  final bool expanded;
  final bool bounce;
  final bool isDismissible;
  final Duration? duration;
  final WidgetWithChildBuilder? containerBuilder;
  final double? closeProgressThreshold;
  final bool useCupertinoStyle;

  @override
  Route<T> createRoute(BuildContext context) {
    final MaterialLocalizations? localizations = Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    final String barrierLabel = localizations?.modalBarrierDismissLabel ?? 'Dismiss';
    final Radius effectiveTopRadius = topRadius ?? const Radius.circular(24);
    final WidgetWithChildBuilder effectiveContainerBuilder =
        containerBuilder ??
        (BuildContext context, Animation<double> _, Widget child) => _CupertinoModalSheetContainer(
          backgroundColor: backgroundColor ?? AppCustomColor.backgroundWhite,
          topRadius: effectiveTopRadius,
          boxShadow: boxShadow,
          child: child,
        );

    if (useCupertinoStyle) {
      return CupertinoModalBottomSheetRoute<T>(
        builder: builder,
        barrierLabel: barrierLabel,
        modalBarrierColor: barrierColor,
        enableDrag: enableDrag,
        expanded: expanded,
        bounce: bounce,
        isDismissible: isDismissible,
        duration: duration,
        containerBuilder: effectiveContainerBuilder,
        closeProgressThreshold: closeProgressThreshold,
        topRadius: effectiveTopRadius,
        transitionBackgroundColor: transitionBackgroundColor,
        previousRouteAnimationCurve: previousRouteAnimationCurve,
        settings: this,
      );
    }

    return ModalSheetRoute<T>(
      builder: builder,
      barrierLabel: barrierLabel,
      modalBarrierColor: barrierColor,
      enableDrag: enableDrag,
      expanded: expanded,
      bounce: bounce,
      isDismissible: isDismissible,
      duration: duration,
      containerBuilder: effectiveContainerBuilder,
      closeProgressThreshold: closeProgressThreshold,
      settings: this,
    );
  }
}

class _CupertinoModalSheetContainer extends StatelessWidget {
  const _CupertinoModalSheetContainer({
    required this.child,
    required this.topRadius,
    required this.backgroundColor,
    this.boxShadow,
  });

  final Widget child;
  final Radius topRadius;
  final Color backgroundColor;
  final BoxShadow? boxShadow;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top + 10;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: topRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              boxShadow ??
                  BoxShadow(
                    color: AppCustomColor.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
