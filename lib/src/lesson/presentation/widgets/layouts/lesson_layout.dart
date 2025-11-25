part of '../../../lesson.dart';

class LessonLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  final bool isLoading;
  const LessonLayout({
    super.key,
    required this.body,
    this.bottom,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  BlocSelector<LessonCubit, LessonState, double>(
                    selector: (state) => state.progress,
                    builder: (context, progress) {
                      return LessonProgressBar();
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          12.verticalSpace,
                          LessonBadge(),
                          ChatInformationWidget(),
                          body,
                          80.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isLoading,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading ? const _LessonLoadingOverlay() : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonLoadingOverlay extends StatelessWidget {
  const _LessonLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppCustomColor.scrimOverlay,
      alignment: Alignment.center,
      child: Container(
        width: math.min(340.w, MediaQuery.sizeOf(context).width - 40.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.black0D.op(0.06),
              blurRadius: 24.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppCustomColor.brandPrimary,
                    AppCustomColor.blue2F,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: AlwaysStoppedAnimation<Color>(AppCustomColor.backgroundWhite),
                ),
              ),
            ),
            14.verticalSpace,
            AppText(
              'Loading your lesson...',
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
            ),
            6.verticalSpace,
            AppText(
              "We're setting things up. This won't take long.",
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
