part of '../../daily_warm_up.dart';

class DailyWarmUpCompletionStep extends StatelessWidget {
  const DailyWarmUpCompletionStep({
    super.key,
    required this.state,
    required this.onStartLesson,
    required this.onExploreMore,
  });

  final DailyWarmUpState state;
  final VoidCallback onStartLesson;
  final VoidCallback onExploreMore;

  @override
  Widget build(BuildContext context) {
    final entity = state.entity;
    final subtitle = entity?.isKeypointCompleted == true ? context.l10n.dailyWarmUp.keepLearningWithNewCourses : context.l10n.dailyWarmUp.readyToContinueProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1FE),
      body: SafeArea(
        child: Stack(
          children: [
            const _DailyWarmUpConfetti(),
            ListView(
              padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 24.h),
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFF4B44CA), Color(0xFFA052FF), Color(0xFFEF81D4), Color(0xFFFF8F8F), Color(0xFFFFCE66)],
                  ).createShader(rect),
                  child: AppText(
                    context.l10n.dailyWarmUp.completeChallenge,
                    textAlign: TextAlign.center,
                    style: AppStyle.text32.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                12.verticalSpace,
                AppText(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text16.copyWith(color: const Color(0xFF364152), fontWeight: FontWeight.w500),
                ),
                32.verticalSpace,
                if (state.suggestedCourse != null)
                  DailyWarmUpCourseCard(course: state.suggestedCourse!)
                else
                  SizedBox(
                    height: 180.h,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                32.verticalSpace,
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DailyWarmUpBottomCta(
            label: context.l10n.dailyWarmUp.startTodaysLesson,
            enabled: state.suggestedCourse != null && !state.isLoadingCourse,
            isLoading: state.isRoutingToRoadmap,
            onPressed: onStartLesson,
          ),
          TextButton(
            onPressed: onExploreMore,
            child: AppText(
              context.l10n.dailyWarmUp.exploreMore,
              style: AppStyle.text16.copyWith(color: const Color(0xFF362F82), fontWeight: FontWeight.w600),
            ),
          ),
          12.verticalSpace,
        ],
      ),
    );
  }
}

class _DailyWarmUpConfetti extends StatelessWidget {
  const _DailyWarmUpConfetti();

  @override
  Widget build(BuildContext context) {
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false) || MediaQuery.accessibleNavigationOf(context)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _DailyWarmUpConfettiPainter()),
      ),
    );
  }
}

class _DailyWarmUpConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const colors = [Color(0xFF554FF0), Color(0xFFEF81D4), Color(0xFFFFCE66), Color(0xFF41AE8C)];
    for (var i = 0; i < 26; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: 0.65);
      final x = (i * 47 % math.max(size.width.toInt(), 1)).toDouble();
      final y = (i * 71 % math.max((size.height * .45).toInt(), 1)).toDouble() + 12;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 8, 4), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
