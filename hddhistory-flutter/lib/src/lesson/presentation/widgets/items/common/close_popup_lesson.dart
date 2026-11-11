part of '../../../../lesson.dart';

class ClosePopupLesson extends StatelessWidget {
  final VoidCallback? onQuit;
  final VoidCallback? onKeepLearning;

  const ClosePopupLesson({
    super.key,
    this.onQuit,
    this.onKeepLearning,
  });

  static void show(
    BuildContext context, {
    required String mode,
    VoidCallback? onQuit,
    VoidCallback? onKeepLearning,
  }) {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      final lessonState = AppDI.injector.get<LessonCubit>().state;
      final cardType = lessonState.currentLearningItem.type == LearningItemType.theory ? 'theory' : 'exercise';
      AppService.instance.appTrackingService.trackKeypointExitPopupView(
        trackingData,
        mode: mode,
        cardType: cardType,
        // The CARD's position in the flow (which document/question is showing),
        // not the learning-item/folder index — see the report: card_index was
        // logging the folder index.
        cardIndex: lessonState.currentLessonIndex,
      );
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => ClosePopupLesson(
        onQuit: onQuit,
        onKeepLearning: onKeepLearning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bake the bottom safe-area inset into the container's own padding
    // instead of wrapping in SafeArea — that keeps the white sheet flush to
    // the bottom edge (no transparent gap showing under it) while the
    // buttons still clear the home indicator / Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heading section
          Column(
            children: [
              AppText(
                context.l10n.lesson.closePopupTitle,
                style: AppStyle.text20.copyWith(
                  color: const Color(0xFF0D121C),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              AppText(
                context.l10n.lesson.closePopupDescription,
                style: AppStyle.text14.copyWith(
                  color: const Color(0xFF364152),
                  fontWeight: FontWeight.w400,
                  height: 1.75,
                ),
                maxLines: 3,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          24.verticalSpace,
          // Buttons section
          Row(
            children: [
              // Quit button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppHaptic.select();
                    final trackingData = KeypointTrackingData.fromContext();
                    if (trackingData != null) {
                      AppService.instance.appTrackingService.trackKeypointExitPopupClick(
                        trackingData,
                        option: 'quit',
                      );
                    }
                    onQuit?.call();
                  },
                  child: Container(
                    height: 54.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE3E8EF),
                        width: 2.w,
                      ),
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    alignment: Alignment.center,
                    child: AppText(
                      context.l10n.lesson.closePopupQuit,
                      style: AppStyle.text16.copyWith(
                        color: const Color(0xFFE34646),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              16.horizontalSpace,
              // Keep learning button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppHaptic.select();
                    final trackingData = KeypointTrackingData.fromContext();
                    if (trackingData != null) {
                      AppService.instance.appTrackingService.trackKeypointExitPopupClick(
                        trackingData,
                        option: 'keep_learning',
                      );
                    }
                    onKeepLearning?.call();
                  },
                  child: Container(
                    height: 54.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5860F),
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    alignment: Alignment.center,
                    child: AppText(
                      context.l10n.lesson.closePopupKeepLearning,
                      style: AppStyle.text16.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          24.verticalSpace,
        ],
      ),
    );
  }
}
