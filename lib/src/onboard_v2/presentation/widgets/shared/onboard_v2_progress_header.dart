part of '../../../onboard_v2.dart';

class OnboardV2ProgressHeader extends StatelessWidget {
  const OnboardV2ProgressHeader({
    super.key,
    required this.activeSegments,
    required this.totalSegments,
    required this.pageStep,
    required this.showBack,
    required this.onBack,
  });

  final int activeSegments;
  final int totalSegments;
  final OnboardV2PageStep pageStep;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final header = SizedBox(
      key: ValueKey('onboard_v2_progress_header_$activeSegments'),
      width: double.infinity,
      height: 48.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const Key('onboard_v2_back_button'),
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, size: 24.w, color: AppCustomColor.textTertiary),
              ),
            ),
          SizedBox(
            width: 240.w,
            child: Row(
              children: List.generate(totalSegments, (index) {
                final active = index < activeSegments;
                return Expanded(
                  child: Container(
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: active ? AppCustomColor.textPrimary : AppCustomColor.borderSecondary,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    final transitionScope = _OnboardV2PageTransitionScope.maybeOf(context);
    if (transitionScope == null) return header;

    return _OnboardV2StickyProgressHeader(
      controller: transitionScope.controller,
      pageIndex: OnboardV2PageStep.values.indexOf(pageStep),
      child: header,
    );
  }
}

class _OnboardV2StickyProgressHeader extends StatelessWidget {
  const _OnboardV2StickyProgressHeader({
    required this.controller,
    required this.pageIndex,
    required this.child,
  });

  final PageController controller;
  final int pageIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final page = _currentPage;
        final distanceFromPage = page - pageIndex;
        final opacity = (1 - distanceFromPage.abs()).clamp(0.0, 1.0).toDouble();

        return IgnorePointer(
          ignoring: opacity < 0.95,
          child: Opacity(
            opacity: Curves.easeOutCubic.transform(opacity),
            child: Transform.translate(
              offset: Offset(distanceFromPage * _viewportWidth(context), 0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  double get _currentPage {
    if (!controller.hasClients) return controller.initialPage.toDouble();
    return controller.page ?? controller.initialPage.toDouble();
  }

  double _viewportWidth(BuildContext context) {
    if (!controller.hasClients) return MediaQuery.sizeOf(context).width;
    return controller.position.viewportDimension;
  }
}
