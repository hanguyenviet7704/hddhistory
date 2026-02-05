part of '../../data_collect.dart';

/// Shows a single motivation slide. The caller pushes this route with the
/// desired [step] so we don't reveal all slides at once.
class DataCollectMotivationStepPage extends StatefulWidget {
  /// 0: welcome, 1: motivationOne, 2: motivationTwo, 3: motivationThree
  final int step;

  const DataCollectMotivationStepPage({super.key, required this.step});

  @override
  State<DataCollectMotivationStepPage> createState() => _DataCollectMotivationStepPageState();
}

class _DataCollectMotivationStepPageState extends State<DataCollectMotivationStepPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        final slide = _buildSlide(context, state);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: slide.isDark ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // onTap: () => _handleTap(context),
            child: Scaffold(
              backgroundColor: slide.backgroundColor,
              body: SafeArea(
                child: MotivationStepContent(
                  imageUrl: slide.imageUrl,
                  title: slide.title,
                  subtitle: slide.subtitle,
                  isDarkBackground: slide.isDark,
                  onSkip: () => _handleTap(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _trackView() {
    final trackingService = AppService.instance.appTrackingService;
    switch (widget.step) {
      case 0:
        trackingService.trackObdWelcomeScrView();
        break;
      case 1:
        trackingService.trackObdMotivation1ScrView();
        break;
      case 2:
        trackingService.trackObdMotivation2ScrView();
        break;
      case 3:
        trackingService.trackObdMotivation3ScrView();
        break;
    }
  }

  void _handleTap(BuildContext context) {
    final trackingService = AppService.instance.appTrackingService;
    switch (widget.step) {
      case 0:
        trackingService.trackObdWelcomeContinue();
        break;
      case 1:
        trackingService.trackObdMotivation1Continue();
        break;
      case 2:
        trackingService.trackObdMotivation2Continue();
        break;
      case 3:
        trackingService.trackObdMotivation3Click();
        break;
    }

    if (widget.step == 3) {
      DataCollectSummaryRoute().go(context);
      return;
    }

    context.read<DataCollectCubit>().goToNextStep();
    context.back();
  }

  _MotivationSlide _buildSlide(BuildContext context, DataCollectState state) {
    final userName = state.userName ?? context.read<DataCollectCubit>().nameController.text;
    final List<OnboardMotivationEntity> motivations = context.read<OnboardCubit>().state.motivations;

    final motivation = (widget.step >= 0 && widget.step < motivations.length) ? motivations[widget.step] : const OnboardMotivationEntity();

    final title = _localTitle(context, userName);

    final bool isDark = widget.step == 0;
    final Color background = isDark ? AppCustomColor.textBrand : AppCustomColor.brandPrimary50;

    return _MotivationSlide(
      title: title,
      subtitle: motivation.content.text,
      imageUrl: motivation.image.isNotEmpty ? motivation.image : AppAsset.images.common.birdWing.path,
      backgroundColor: background,
      isDark: isDark,
    );
  }

  String _localTitle(BuildContext context, String? userName) {
    return switch (widget.step) {
      0 => context.text.onboarding.onboardingMotivationWelcomeTitle(userName: userName ?? ''),
      1 => context.text.onboarding.onboardingMotivationOneTitle(userName: userName ?? ''),
      2 => context.text.onboarding.onboardingMotivationTwoTitle(userName: userName ?? ''),
      _ => context.text.onboarding.onboardingMotivationThreeTitle,
    };
  }
}

class _MotivationSlide {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color backgroundColor;
  final bool isDark;

  _MotivationSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.backgroundColor,
    required this.isDark,
  });
}
