part of '../../../onboard.dart';

class IntroContent extends StatelessWidget {
  final OnboardContent content;
  const IntroContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Spacer(),
          CharacterSection(content: content),
          ContentCard(content: content),
          20.verticalSpace,
        ],
      ),
    );
  }
}
