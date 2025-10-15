part of '../../onboard.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardChatItem(
        title: "Hi! I'm /Tên mascot",
        subtitle: "Let's start by telling me a little about yourself",
        characterImagePath: "assets/images/common/bird_stand.png",
      ),
    );
  }
}
