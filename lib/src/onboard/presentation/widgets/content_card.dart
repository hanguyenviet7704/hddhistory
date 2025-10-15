part of '../../onboard.dart';

class ContentCard extends StatelessWidget {
  final OnboardContent content;
  const ContentCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 335.w,
      height: 260.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF5B616D).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(AppAsset.svg.common.star, width: 24.w, height: 24.h),
            8.verticalSpace,
            ContentText(content: content),
            const Spacer(),
            PageIndicator(),
          ],
        ),
      ),
    );
  }
}

class ContentText extends StatelessWidget {
  final OnboardContent content;
  const ContentText({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey<String>('${content.title}_${content.subtitle}_${content.description}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.title.isNotEmpty)
            AppText(
              content.title,
              maxLines: 2,
              style: AppStyle.text20.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0D121C),
                height: 1.5,
              ),
            ),
          if (content.subtitle.isNotEmpty) ...[
            12.verticalSpace,
            AppText(
              content.subtitle,
              maxLines: 2,
              style: AppStyle.text20.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF554FF0),
                height: 1.5,
              ),
            ),
          ],
          if (content.description.isNotEmpty) ...[
            12.verticalSpace,
            AppText(
              content.description,
              maxLines: 2,
              style: AppStyle.text20.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0D121C),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IntroCubit>();

    return BlocBuilder<IntroCubit, IntroState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              cubit.onboardContents.length,
              (index) {
                final isActive = state.currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: isActive ? 24.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF462BF4) : const Color(0xFFC1C5CD),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
