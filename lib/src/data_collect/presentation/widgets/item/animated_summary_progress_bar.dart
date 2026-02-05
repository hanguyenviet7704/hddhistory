part of '../../../data_collect.dart';

class AnimatedSummaryProgressBar extends StatefulWidget {
  final String title;
  final double progress;
  final Color progressColor;
  final Duration delay;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const AnimatedSummaryProgressBar({
    super.key,
    required this.title,
    required this.progress,
    required this.progressColor,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1500),
    this.onAnimationComplete,
  });

  @override
  State<AnimatedSummaryProgressBar> createState() => _AnimatedSummaryProgressBarState();
}

class _AnimatedSummaryProgressBarState extends State<AnimatedSummaryProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasReportedCompletion = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = _createAnimation(begin: 0.0, end: widget.progress);

    _startWithDelay();
  }

  Animation<double> _createAnimation({required double begin, required double end}) {
    final animation = Tween<double>(
      begin: begin,
      end: end.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    animation.addStatusListener(_handleStatusChange);
    return animation;
  }

  void _handleStatusChange(AnimationStatus status) {
    final isCompleted = status == AnimationStatus.completed;
    final reachedFullProgress = widget.progress >= 1.0 && !_hasReportedCompletion;

    if (isCompleted && reachedFullProgress) {
      _hasReportedCompletion = true;
      widget.onAnimationComplete?.call();
    }
  }

  void _startWithDelay() {
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _hasStarted = true;
      _controller.forward(from: 0);
    });
  }

  void _animateToProgress(double newProgress) {
    _animation.removeStatusListener(_handleStatusChange);

    final currentValue = _animation.value;
    _controller.duration = widget.duration;
    _animation = _createAnimation(begin: currentValue, end: newProgress);

    if (_hasStarted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSummaryProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      if (widget.progress < 1.0) {
        _hasReportedCompletion = false;
      }

      _animateToProgress(widget.progress);
    }
  }

  @override
  void dispose() {
    _animation.removeStatusListener(_handleStatusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Title and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  widget.title,
                  style: AppStyle.textBold16.copyWith(
                    color: const Color(0xFF0D121C), // Text/Primary
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 20.h,
                  width: 36.w,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: _animation.value >= 0.999
                        ? AppAsset.icons.app.icTick.image(
                            key: const ValueKey('progress-complete'),
                            width: 20.w,
                            height: 20.w,
                          )
                        : AppText(
                            '${(_animation.value * 100).toInt()}%',
                            key: const ValueKey('progress-percent'),
                            style: AppStyle.textBold14.copyWith(
                              color: const Color(0xFFAAB8CD), // Text/Quaternary
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                  ),
                ),
              ],
            ),

            8.verticalSpace,

            // Progress bar
            Container(
              height: 11.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E8EF), // Border/Default
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 11.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E8EF), // Border/Default
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _animation.value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 11.h,
                      decoration: BoxDecoration(
                        color: widget.progressColor,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
