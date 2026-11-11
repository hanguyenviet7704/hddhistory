part of '../../../onboard_v2.dart';

/// Vòng lặp `v2step` của S7: mỗi thẻ trôi lên + hiện dần, giữ nguyên gần hết
/// chu kỳ rồi mờ đi và lặp lại, thẻ sau trễ hơn thẻ trước 180ms.
///
/// Mốc của design trên chu kỳ 4s: 0% mờ hẳn và thấp hơn 14px → 12% hiện đủ và
/// về đúng chỗ → giữ tới 90% → 100% mờ lại.
///
/// BẪY: `PageView` dựng sẵn trang kề bên nên widget này được tạo từ lúc user
/// còn ở S6. Chuỗi chỉ chạy khi THẬT SỰ đang đứng ở S7, nếu không user bước
/// sang sẽ rơi vào giữa chu kỳ, có khi đúng đoạn đang mờ đi.
class OnboardV2StepRevealCard extends StatefulWidget {
  const OnboardV2StepRevealCard({super.key, required this.index, required this.child});

  /// Thứ tự thẻ, quyết định độ trễ vào chu kỳ.
  final int index;
  final Widget child;

  @override
  State<OnboardV2StepRevealCard> createState() => _OnboardV2StepRevealCardState();
}

class _OnboardV2StepRevealCardState extends State<OnboardV2StepRevealCard> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 4000);
  static const _stagger = Duration(milliseconds: 180);
  static const _curve = Cubic(0.22, 0.61, 0.36, 1);
  static const _fadeInEnd = 0.12;
  static const _holdEnd = 0.90;
  static const _enterOffset = 14.0;

  late final AnimationController _controller;
  Timer? _startTimer;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sync(context.read<OnboardV2Cubit>().state.currentPage == OnboardV2PageStep.p7How);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// Bật/tắt vòng lặp. Gọi từ listener hoặc post-frame chứ KHÔNG gọi trong
  /// `build`: đổi `_controller.value` sẽ báo listener ngay lập tức, mà làm vậy
  /// giữa lúc dựng cây là đánh dấu rebuild trong build — Flutter ném lỗi.
  void _sync(bool isCurrentPage) {
    if (_reduceMotion) {
      _stop(settleVisible: true);
      return;
    }
    if (isCurrentPage) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_reduceMotion || _controller.isAnimating) return;
    _startTimer?.cancel();
    _controller.value = 0;
    _startTimer = Timer(_stagger * widget.index, () {
      if (!mounted || _reduceMotion) return;
      unawaited(_controller.repeat());
    });
  }

  void _stop({bool settleVisible = false}) {
    _startTimer?.cancel();
    _controller
      ..stop()
      // Dừng ở khung "hiện đủ" để thẻ không kẹt lại trong trạng thái mờ khi
      // user tắt hiệu ứng hoặc rời màn rồi quay lại.
      ..value = settleVisible ? _fadeInEnd : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardV2Cubit, OnboardV2State>(
      listenWhen: (previous, current) => previous.currentPage != current.currentPage,
      listener: (_, state) => _sync(state.currentPage == OnboardV2PageStep.p7How),
      child: _reduceMotion
          ? widget.child
          : AnimatedBuilder(
              animation: _controller,
              child: widget.child,
              builder: (context, child) {
                final progress = _resolve(_controller.value);
                return Opacity(
                  opacity: progress.opacity,
                  child: Transform.translate(offset: Offset(0, progress.offsetY), child: child),
                );
              },
            ),
    );
  }

  _StepRevealFrame _resolve(double t) {
    if (t < _fadeInEnd) {
      final eased = _curve.transform(t / _fadeInEnd);
      return _StepRevealFrame(opacity: eased, offsetY: _enterOffset * (1 - eased));
    }
    if (t < _holdEnd) return const _StepRevealFrame(opacity: 1, offsetY: 0);
    final eased = _curve.transform((t - _holdEnd) / (1 - _holdEnd));
    return _StepRevealFrame(opacity: 1 - eased, offsetY: _enterOffset * eased);
  }
}

class _StepRevealFrame {
  const _StepRevealFrame({required this.opacity, required this.offsetY});

  final double opacity;
  final double offsetY;
}
