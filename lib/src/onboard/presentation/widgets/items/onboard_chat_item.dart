part of '../../../onboard.dart';

class OnboardChatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String characterImagePath;
  final VoidCallback? onContinue;

  const OnboardChatItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.characterImagePath,
    this.onContinue,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
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
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      children: [
        16.verticalSpace,
        ContinueButtonWidget(
          onPressed: onContinue,
        ),
        16.verticalSpace,
      ],
    );
  }
}
