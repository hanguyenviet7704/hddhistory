part of '../../onboard.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardChatItem(
        title: context.text.onboarding.onboardingMascotGreetingTitle,
        subtitle: context.text.onboarding.onboardingMascotGreetingMessage,
        characterImagePath: AppAsset.images.common.birdStand.path,
      ),
    );
  }
}
