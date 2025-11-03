part of '../../onboard.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCCF1EE),
        image: DecorationImage(image: AssetImage(AppAsset.images.common.introBg.path), alignment: Alignment.topCenter),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: InkWell(
            onTap: () {
              IntroState state = context.read<IntroCubit>().state;
              if (state.currentPage < state.intros.length - 1) {
                context.read<IntroCubit>().setPage(state.currentPage + 1);
                return;
              }
              OnboardRoute().go(context);
            },
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
                        context.text.skip,
                        style: AppStyle.text16.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: BlocBuilder<IntroCubit, IntroState>(
                    builder: (context, state) {
                      final content = state.intros[state.currentPage];
                      return IntroContent(content: content);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
