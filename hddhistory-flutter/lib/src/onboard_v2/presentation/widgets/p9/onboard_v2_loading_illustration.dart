part of '../../../onboard_v2.dart';

/// Hình minh hoạ S9: tờ lộ trình nghiêng, chiếc kính lúp lượn một vòng quanh nó
/// rồi về chỗ cũ (`v2mag`, 3,4s, lặp mãi).
///
/// Hai file SVG dùng CHUNG hệ toạ độ `viewBox 0 0 366 240` nên chồng khít lên
/// nhau; chuyển động nằm ở Flutter chứ không nằm trong file, vì trình vẽ SVG
/// của app không chạy animation CSS.
class OnboardV2LoadingIllustration extends StatefulWidget {
  const OnboardV2LoadingIllustration({super.key});

  /// Kích thước design vẽ ra, cũng là tỉ lệ của `viewBox`.
  static const width = 300.0;
  static const height = 197.0;

  @override
  State<OnboardV2LoadingIllustration> createState() => _OnboardV2LoadingIllustrationState();
}

class _OnboardV2LoadingIllustrationState extends State<OnboardV2LoadingIllustration> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 3400);

  /// Từ đơn vị TRONG nhóm SVG (nơi design viết các mốc `translate`) ra điểm ảnh
  /// của khung 300×197: nhóm bị thu 0,72 rồi cả viewBox thu 300/366.
  static const _innerToPixel = 0.72 * (OnboardV2LoadingIllustration.width / 366);

  /// Tâm xoay 323,150 trong hệ toạ độ ấy, quy về [Alignment] của khung.
  static const _pivot = Alignment(0.489, 0.149);

  /// Bốn mốc của `v2mag`: dịch (theo đơn vị trong nhóm) và xoay (độ).
  static const _waypoints = <(double, double, double)>[
    (0, 0, 0),
    (-30, -46, -10),
    (-96, -30, 6),
    (-46, 6, -4),
    (0, 0, 0),
  ];

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = OnboardV2LoadingIllustration.width.w;
    final height = OnboardV2LoadingIllustration.height.w;
    final magnifier = SvgPicture.asset(AppAsset.svg.app.obLoadingMagnifier, width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          SvgPicture.asset(AppAsset.svg.app.obLoadingPlan, width: width, height: height),
          if (_reduceMotion)
            magnifier
          else
            AnimatedBuilder(
              animation: _controller,
              child: magnifier,
              builder: (context, child) {
                final frame = _resolve(_controller.value);
                return Transform(
                  alignment: _pivot,
                  transform: Matrix4.identity()
                    ..translateByDouble((frame.$1 * _innerToPixel).w, (frame.$2 * _innerToPixel).w, 0, 1)
                    ..rotateZ(frame.$3 * math.pi / 180),
                  child: child,
                );
              },
            ),
        ],
      ),
    );
  }

  /// Nội suy giữa hai mốc kề nhau, mỗi chặng dùng đường cong `ease-in-out` như
  /// design.
  (double, double, double) _resolve(double t) {
    final segments = _waypoints.length - 1;
    final scaled = (t * segments).clamp(0.0, segments.toDouble());
    final index = scaled.floor().clamp(0, segments - 1);
    final eased = Curves.easeInOut.transform(scaled - index);
    final from = _waypoints[index];
    final to = _waypoints[index + 1];
    return (
      ui.lerpDouble(from.$1, to.$1, eased)!,
      ui.lerpDouble(from.$2, to.$2, eased)!,
      ui.lerpDouble(from.$3, to.$3, eased)!,
    );
  }
}
