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
      body: SafePage(
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
                      child: Column(
                        children: [
                          12.verticalSpace,
                          LessonBadge(),
                          // ChatInformationWidget(),
                          Expanded(child: body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocSelector<LessonCubit, LessonState, bool>(
                  selector: (state) => state.isBottomButtonVisible,
                  builder: (context, isVisible) {
                    if (bottom == null) return const SizedBox.shrink();
                    return _AnimatedLessonBottomBar(
                      isVisible: isVisible,
                      child: bottom!,
                    );
                  },
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

class _AnimatedLessonBottomBar extends StatelessWidget {
  const _AnimatedLessonBottomBar({
    required this.isVisible,
    required this.child,
  });

  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 0.2),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: child,
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
