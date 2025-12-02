part of '../../../lesson.dart';

class LessonLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  final bool isLoading;
  const LessonLayout({
    super.key,
    required this.body,
    this.bottom,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Unfocused(
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
        width: 64.w,
        height: 64.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppCustomColor.brandPrimary,
              AppCustomColor.brandPrimary50,
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
    );
  }
}
