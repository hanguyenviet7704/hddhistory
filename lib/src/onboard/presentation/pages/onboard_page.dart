part of '../../onboard.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardChatItem(
        title: context.l10n.onboarding.onboardingMascotGreetingTitle,
        subtitle: context.l10n.onboarding.onboardingMascotGreetingMessage,
        characterImagePath: AppAsset.images.common.birdStand.path,
      ),
    );
  }
}
