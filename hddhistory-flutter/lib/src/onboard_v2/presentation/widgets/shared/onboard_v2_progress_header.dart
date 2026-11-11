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
    // Design: mũi tên lùi 22px, cách 14px, rồi thanh chiếm HẾT phần còn lại với
    // các nấc cao 6px cách nhau 6px, nấc đã qua màu thương hiệu. Bản cũ để
    // thanh rộng cố định 240 nằm giữa và nấc cao 8px màu gần đen, nên trông vừa
    // ngắn vừa dày hơn bản vẽ. Ô mũi tên luôn chiếm chỗ kể cả màn không có nút
    // lùi, để thanh không nhảy ngang giữa các bước.
    final header = SizedBox(
      key: ValueKey('onboard_v2_progress_header_$activeSegments'),
      width: double.infinity,
      height: 30.h,
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: showBack
                ? IconButton(
                    key: const Key('onboard_v2_back_button'),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
                    onPressed: onBack == null
                        ? null
                        : () {
                            AppHaptic.select();
                            onBack!();
                          },
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.w, color: AppCustomColor.textPrimary),
                  )
                : null,
          ),
          14.horizontalSpace,
          Expanded(
            child: Row(
              children: List.generate(totalSegments, (index) {
                final active = index < activeSegments;
                return Expanded(
                  child: Container(
                    height: 6.h,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      color: active ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                      borderRadius: BorderRadius.circular(99.r),
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
