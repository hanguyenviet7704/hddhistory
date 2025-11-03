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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation =
        Tween<double>(
            begin: 0.0,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && widget.onAnimationComplete != null) {
              widget.onAnimationComplete!();
            }
          });

    // Start the animation after the specified delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
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
                AppText(
                  '${(_animation.value * 100).toInt()}%',
                  style: AppStyle.textBold14.copyWith(
                    color: const Color(0xFFAAB8CD), // Text/Quaternary
                    fontWeight: FontWeight.w600,
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
