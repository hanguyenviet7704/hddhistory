part of '../../../course.dart';

class CompletedLevelAdditionalContentRequestCard extends StatelessWidget {
  final CourseLevel level;
  final CompletedLevelAdditionalContentRequestPromptStatus status;
  final bool isSubmitting;
  final Future<bool> Function()? onNoSelected;
  final VoidCallback? onYesSelected;

  const CompletedLevelAdditionalContentRequestCard({
    super.key,
    required this.level,
    required this.status,
    this.isSubmitting = false,
    this.onNoSelected,
    this.onYesSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!status.isVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 60.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54.w,
            height: 54.w,
            child: AppAsset.images.app.flagCircle.image(
              width: 54.w,
              height: 54.w,
              fit: BoxFit.contain,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompleteLevelLabel(level: level),
                12.verticalSpace,
                _AdditionalContentQuestionPanel(
                  status: status,
                  isSubmitting: isSubmitting,
                  onNoSelected: onNoSelected,
                  onYesSelected: onYesSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteLevelLabel extends StatelessWidget {
  final CourseLevel level;

  const _CompleteLevelLabel({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF5446CF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: AppText(
        context.l10n.courseroadmap.additionalContentRequestCompleteLevel(level: level.number),
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textWhite,
          fontWeight: FontWeight.w700,
          height: 1.75,
        ),
        maxLines: 1,
      ),
    );
  }
}
