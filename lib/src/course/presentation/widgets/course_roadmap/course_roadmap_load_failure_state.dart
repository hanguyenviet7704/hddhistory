part of '../../../course.dart';

/// Shown in place of the roadmap list when the last load FAILED for a known
/// course (as opposed to the user genuinely having no course yet — that case
/// keeps [CourseEmptyState]). Offers an inline retry so the user isn't stuck
/// on a blank screen where the only recovery is pull-to-refresh or an app
/// restart.
class CourseRoadmapLoadFailureState extends StatelessWidget {
  final VoidCallback onRetry;

  const CourseRoadmapLoadFailureState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              context.l10n.common.errorOopsSomethingWentWrongWhileLoading,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textTertiary,
              ),
            ),
            12.verticalSpace,
            DButton(
              key: const Key('roadmap-load-failure-retry'),
              text: context.l10n.monetization.retry,
              size: Size(140.w, 44.h),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
