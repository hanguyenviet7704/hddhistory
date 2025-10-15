part of '../../../onboard.dart';

class OnboardChatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String characterImagePath;

  const OnboardChatItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.characterImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFEBEAFD)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              20.verticalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ChatBubbleWidget(
                      title: title,
                      subtitle: subtitle,
                    ),

                    16.verticalSpace,
                    CharacterIllustrationWidget(
                      imagePath: characterImagePath,
                    ),
                  ],
                ),
              ),
              16.verticalSpace,
              ContinueButtonWidget(
                onPressed: () {},
              ),
              16.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
