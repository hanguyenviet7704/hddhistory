part of '../../onboard.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardChatItem(
        title: context.text.onboardingMascotGreetingTitle,
        subtitle: context.text.onboardingMascotGreetingMessage,
        characterImagePath: AppAsset.images.common.birdStand.path,
      ),
    );
  }
}
