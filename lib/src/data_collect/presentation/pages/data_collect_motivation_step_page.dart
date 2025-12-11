part of '../../data_collect.dart';

/// Shows a single motivation slide. The caller pushes this route with the
/// desired [step] so we don't reveal all slides at once.
class DataCollectMotivationStepPage extends StatelessWidget {
  /// 0: welcome, 1: motivationOne, 2: motivationTwo, 3: motivationThree
  final int step;

  const DataCollectMotivationStepPage({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        final slide = _buildSlide(context, state);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: slide.isDark ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(context),
            child: Scaffold(
              backgroundColor: slide.backgroundColor,
              body: SafeArea(
                child: MotivationStepContent(
                  imageUrl: slide.imageUrl,
                  title: slide.title,
                  subtitle: slide.subtitle,
                  isDarkBackground: slide.isDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    DataCollectRoute().go(context);
  }

  _MotivationSlide _buildSlide(BuildContext context, DataCollectState state) {
    final userName = state.userName ?? context.read<DataCollectCubit>().nameController.text;
    final List<OnboardMotivationEntity> motivations = context.read<OnboardCubit>().state.motivations;

    final motivation = (step >= 0 && step < motivations.length) ? motivations[step] : const OnboardMotivationEntity();

    final title = _localTitle(context, userName);

    final bool isDark = step == 0;
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
    return switch (step) {
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
