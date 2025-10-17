part of '../../onboard.dart';

class ContentCard extends StatelessWidget {
  final OnboardIntroEntity content;
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
  final OnboardIntroEntity content;
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
      child: AppText(
        key: ValueKey<String>('${content.title.text}_${content.content.text}'),
        content.content.text,
        maxLines: 10,
        style: AppStyle.text20.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
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
          width: double.infinity,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              cubit.state.intros.length,
              (index) {
                final isActive = state.currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: 8.w,
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
