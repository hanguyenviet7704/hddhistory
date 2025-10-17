part of '../../onboard.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IntroCubit>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCCF1EE),
        image: DecorationImage(image: AssetImage(AppAsset.images.common.introBg.path), alignment: Alignment.topCenter),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    OnboardRoute().go(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: AppText(
                      'Skip',
                      style: AppStyle.text16.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: BlocBuilder<IntroCubit, IntroState>(
                  builder: (context, state) {
                    final content = cubit.onboardContents[state.currentPage];
                    return GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity!;

                        // Swiped left - next page
                        if (velocity < 0 && state.currentPage < cubit.onboardContents.length - 1) {
                          cubit.setPage(state.currentPage + 1);
                          return;
                        }

                        // Swiped right - previous page
                        if (velocity > 0 && state.currentPage > 0) {
                          cubit.setPage(state.currentPage - 1);
                        }
                      },
                      child: IntroContent(content: content),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
