part of '../../lesson.dart';

enum LessonCompleteType { keypoint, lesson }

class LessonCompletePage extends StatefulWidget {
  final LessonCompleteType type;
  final String? keypointTitle;
  final double? progress;

  const LessonCompletePage({
    super.key,
    this.type = LessonCompleteType.keypoint,
    this.keypointTitle,
    this.progress,
  });

  @override
  State<LessonCompletePage> createState() => _LessonCompletePageState();
}

class _LessonCompletePageState extends State<LessonCompletePage> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.type == LessonCompleteType.lesson) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _confettiController.forward();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.type == LessonCompleteType.keypoint) _buildKeypointHeader(),
            if (widget.type == LessonCompleteType.lesson) _buildLessonHeader(),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 36.h,
                ),
                child: widget.type == LessonCompleteType.keypoint ? _buildKeypointContent() : _buildLessonContent(),
              ),
            ),

            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypointHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16.r),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0xFF41AE8C),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  'BUILDING NONVERBAL PRESENCE',
                  style: AppStyle.text10.copyWith(
                    color: const Color(0xFF7F8EA4),
                    fontWeight: FontWeight.w500,
                    height: 1.75,
                  ),
                ),
                AppText(
                  widget.keypointTitle ?? 'Maintaining Appropriate Eye Contact',
                  style: AppStyle.textBold14.copyWith(
                    color: const Color(0xFF364152),
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Center(
        child: AppText(
          'Building Nonverbal Presence',
          style: AppStyle.textBold14.copyWith(
            color: const Color(0xFF364152),
            height: 1.75,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypointContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 155.w,
          height: 161.h,
          color: const Color(0xFFAAB8CD),
        ),
        16.verticalSpace,

        AppText(
          context.text.lessonKeypointCompleteTitle,
          style: AppStyle.textBold24.copyWith(
            color: const Color(0xFF1A202C),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        8.verticalSpace,

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 10.h,
              width: 97.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E8EF),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.progress ?? 0.68,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF554FF0),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),
            8.horizontalSpace,
            AppText(
              '${((widget.progress ?? 0.68) * 100).toInt()}%',
              style: AppStyle.textBold12.copyWith(
                color: const Color(0xFF0D121C),
                height: 1.75,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLessonContent() {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_confettiController.value * 0.2),
                  child: Opacity(
                    opacity: 1.0 - (_confettiController.value * 0.3),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF41AE8C),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 30.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            24.verticalSpace,

            AppText(
              context.text.lessonCompleteTitle,
              style: AppStyle.textBold24.copyWith(
                color: const Color(0xFF1A202C),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            4.verticalSpace,
            AppText(
              context.text.lessonCompleteSubtitle,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF7F8EA4),
                height: 1.75,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        if (_confettiController.value > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  progress: _confettiController.value,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return GestureDetector(
      onTap: () {
        if (widget.type == LessonCompleteType.keypoint) {
          context.read<LessonCubit>().continueToNextLearningItem();
        } else {
          context.pop();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 16.h,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Container(
          height: 54.h,
          decoration: BoxDecoration(
            color: AppCustomColor.blue55,
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Center(
            child: AppText(
              widget.type == LessonCompleteType.keypoint ? context.text.exerciseSkipButton : context.text.lessonCompleteButton,
              style: AppStyle.textBold16.copyWith(
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random random = math.Random(42);

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final List<Color> colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFF06292),
      const Color(0xFF9575CD),
    ];

    for (int i = 0; i < 50; i++) {
      final double startX = random.nextDouble() * size.width;
      final double startY = -20;
      final double endY = size.height * progress * (0.5 + random.nextDouble() * 0.5);

      final double x = startX + (random.nextDouble() - 0.5) * 100 * progress;
      final double y = startY + endY;

      if (y < 0 || y > size.height) continue;

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final double confettiSize = 4 + random.nextDouble() * 6;
      final double rotation = random.nextDouble() * math.pi * 4 * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (i % 3 == 0) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: confettiSize, height: confettiSize * 1.5),
          paint,
        );
      } else if (i % 3 == 1) {
        canvas.drawCircle(Offset.zero, confettiSize / 2, paint);
      } else {
        final path = ui.Path();
        path.moveTo(0, -confettiSize);
        path.lineTo(confettiSize * 0.866, confettiSize * 0.5);
        path.lineTo(-confettiSize * 0.866, confettiSize * 0.5);
        path.close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => progress != oldDelegate.progress;
}
