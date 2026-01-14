part of '../../../lesson.dart';

class LessonLayout extends StatefulWidget {
  final Widget body;
  final Widget? bottom;
  final bool isLoading;
  final VoidCallback? onScroll;
  const LessonLayout({
    super.key,
    required this.body,
    this.bottom,
    this.isLoading = true,
    this.onScroll,
  });

  @override
  State<LessonLayout> createState() => _LessonLayoutState();
}

class _LessonLayoutState extends State<LessonLayout> {
  bool _didNotifyScroll = false;

  bool _handleScroll(ScrollNotification notification) {
    if (widget.onScroll == null) return false;
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _didNotifyScroll = false;
      } else if (!_didNotifyScroll) {
        _didNotifyScroll = true;
        widget.onScroll?.call();
      }
    }
    return false;
  }

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
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleScroll,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              12.verticalSpace,
                              LessonBadge(),
                              ChatInformationWidget(),
                              widget.body,
                              80.verticalSpace,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.bottom != null) widget.bottom!,
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !widget.isLoading,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isLoading ? const _LessonLoadingOverlay() : const SizedBox.shrink(),
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
