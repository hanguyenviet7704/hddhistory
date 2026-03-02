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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                  return _OnboardIntroduceContent(
                    intros: onboardState.onboardData.intro,
                    pageController: _pageController,
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardIntroduceContent extends StatefulWidget {
  final List<OnboardIntroEntity> intros;
  final PageController pageController;

  const _OnboardIntroduceContent({required this.intros, required this.pageController});

  @override
  State<_OnboardIntroduceContent> createState() => _OnboardIntroduceContentState();
}

class _OnboardIntroduceContentState extends State<_OnboardIntroduceContent> {
  int? _lastTrackedPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackIntroView(context.read<IntroCubit>().state.currentPage);
    });
  }

  void _trackIntroView(int page) {
    if (_lastTrackedPage == page) return;
    _lastTrackedPage = page;

    if (page <= 0) {
      AppService.instance.appTrackingService.trackObdIntro1ScrView();
      return;
    }
    AppService.instance.appTrackingService.trackObdIntro2ScrView();
  }

  void _onNext(IntroState state, BuildContext context) {
    final isLastPage = state.intros.isNotEmpty && state.currentPage == state.intros.length - 1;

    if (isLastPage) {
      AppService.instance.appTrackingService.trackObdIntro2Click();
      final dataCollectCubit = AppDI.injector.get<DataCollectCubit>();
      dataCollectCubit.setShouldSkipBranchingFlow(false);
      dataCollectCubit.setShouldSkipAnonymousLogin(false);
      DataCollectRoute().go(context);
      return;
    }

    AppService.instance.appTrackingService.trackObdIntro1Continue();
    widget.pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  String _languageSourceForPage(int page) {
    return page <= 0 ? 'intro1' : 'intro2';
  }

  @override
  Widget build(BuildContext context) {
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
              onLanguageTap: () => IntroLanguageSheet.show(
                context,
                source: _languageSourceForPage(introState.currentPage),
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: BlocListener<IntroCubit, IntroState>(
                listenWhen: (previous, current) => previous.currentPage != current.currentPage,
                listener: (context, state) {
                  _trackIntroView(state.currentPage);
                  if (state.currentPage != widget.pageController.page?.round()) {
                    widget.pageController.animateToPage(
                      state.currentPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: BlocBuilder<LocaleCubit, AppLocale>(
                  builder: (context, _) {
                    return PageView.builder(
                      controller: widget.pageController,
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
                  onPressed: () => _onNext(introState, context),
                ),
              ),
            ),
          ],
        );
      },
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
