part of '../../../roleplay.dart';

class RoleplayLeadingText extends StatelessWidget {
  final LeadingTextEntity leadingText;
  final RoleplayAudioController? audioController;

  const RoleplayLeadingText({
    super.key,
    required this.leadingText,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = leadingText.textColor.toHexColor;

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            leadingText.content.text,
            textAlign: TextAlign.center,
            style: AppStyle.text12.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 20,
          ),
          if (audioController?.hasAudio ?? false) ...[
            RoleplayAudioButton(
              controller: audioController,
              iconColor: Colors.transparent,
              disabledUI: true,
            ),
          ],
        ],
      ),
    );
  }
}
