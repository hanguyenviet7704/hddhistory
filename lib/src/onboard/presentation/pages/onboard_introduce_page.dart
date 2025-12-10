part of '../../onboard.dart';

class OnboardIntroducePage extends StatelessWidget {
  const OnboardIntroducePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OnboardIntroduceView();
  }
}

class _OnboardIntroduceView extends StatefulWidget {
  const _OnboardIntroduceView();

  @override
  State<_OnboardIntroduceView> createState() => _OnboardIntroduceViewState();
}

class _OnboardIntroduceViewState extends State<_OnboardIntroduceView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardCubit>().loadAllOnboards();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(IntroState state) {
    final isLastPage = state.intros.isNotEmpty && state.currentPage == state.intros.length - 1;

    if (isLastPage) {
      DataCollectRoute().go(context);
      return;
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (sheetContext) {
        final selectedLocale = sheetContext.read<LocaleCubit>().state;

        return IntroLanguageSheet(
          selectedLocale: selectedLocale,
          onSelected: (locale) {
            context.read<LocaleCubit>().setLocale(locale);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<OnboardCubit, OnboardState>(
            builder: (context, onboardState) {
              switch (onboardState.status) {
                case OnboardStatus.initial:
                case OnboardStatus.loading:
                  return const _IntroduceLoading();
                case OnboardStatus.failure:
                  return _IntroduceError(
                    message: onboardState.errorMessage,
                    onRetry: () => context.read<OnboardCubit>().loadAllOnboards(),
                  );
                case OnboardStatus.success:
                  return BlocBuilder<IntroCubit, IntroState>(
                    builder: (context, introState) {
                      if (introState.intros.isEmpty) {
                        return _IntroduceError(
                          message: context.text.common.errorNoInternetConnection,
                          onRetry: () => context.read<OnboardCubit>().loadAllOnboards(),
                        );
                      }

                      return Column(
                        children: [
                          8.verticalSpace,
                          IntroHeader(
                            onLanguageTap: _showLanguageSheet,
                          ),
                          16.verticalSpace,
                          Expanded(
                            child: BlocListener<IntroCubit, IntroState>(
                              listenWhen: (previous, current) => previous.currentPage != current.currentPage,
                              listener: (context, state) {
                                if (state.currentPage != _pageController.page?.round()) {
                                  _pageController.animateToPage(
                                    state.currentPage,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: BlocBuilder<LocaleCubit, AppLocale>(
                                builder: (context, _) {
                                  return PageView.builder(
                                    controller: _pageController,
                                    itemCount: introState.intros.length,
                                    onPageChanged: (index) => context.read<IntroCubit>().setPage(index),
                                    physics: const ClampingScrollPhysics(),
                                    itemBuilder: (context, index) => IntroStepContent(
                                      intro: introState.intros[index],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
                            child: SizedBox(
                              width: 200.w,
                              child: ContinueButtonWidget(
                                text: introState.currentPage == introState.intros.length - 1
                                    ? context.text.onboarding.onboardingStartNowButton
                                    : context.text.onboarding.onboardingSkipGreetingButton,
                                onPressed: () => _onNext(introState),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _IntroduceLoading extends StatelessWidget {
  const _IntroduceLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _IntroduceError extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _IntroduceError({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
            ),
            16.verticalSpace,
            DButton(
              onPressed: onRetry,
              text: context.text.common.canvasTryAgain,
              size: Size(140.w, 44.h),
              backgroundColor: AppCustomColor.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ],
        ),
      ),
    );
  }
}
