part of '../../video_lesson.dart';

class _VideoLessonBlockingOverlayLayout extends StatelessWidget {
  const _VideoLessonBlockingOverlayLayout({
    required this.card,
    this.cta,
    this.pinCtaToBottom = false,
  });

  final Widget card;
  final Widget? cta;
  final bool pinCtaToBottom;

  @override
  Widget build(BuildContext context) {
    if (pinCtaToBottom) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.w,
            28.h,
            24.w,
            max(20.h, MediaQuery.viewPaddingOf(context).bottom + 12.h),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 390.w),
                    child: card,
                  ),
                ),
              ),
              if (cta != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 390.w),
                  child: cta!,
                ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24.w,
          28.h,
          24.w,
          max(20.h, MediaQuery.viewPaddingOf(context).bottom + 12.h),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 390.w),
                child: card,
              ),
            ),
            if (cta != null) ...[
              28.verticalSpace,
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 390.w),
                child: cta!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
