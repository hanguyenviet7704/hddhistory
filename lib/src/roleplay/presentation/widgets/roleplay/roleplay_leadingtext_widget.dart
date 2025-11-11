part of '../../../roleplay.dart';

class RoleplayLeadingTextCard extends StatelessWidget {
  final LeadingTextEntity leadingText;
  final RoleplayAudioController? audioController;

  const RoleplayLeadingTextCard({
    super.key,
    required this.leadingText,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = leadingText.textColor.toHexColor == Colors.transparent ? AppCustomColor.textWhite : leadingText.textColor.toHexColor;
    final Color frameColor = leadingText.frameColor.toHexColor == Colors.transparent ? Colors.white.withValues(alpha: 0.4) : leadingText.frameColor.toHexColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayLeadingSurface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: frameColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                leadingText.content,
                textAlign: TextAlign.center,
                style: AppStyle.text12.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
              ),
              if (audioController?.hasAudio ?? false) ...[
                16.verticalSpace,
                RoleplayAudioButton(
                  controller: audioController,
                  iconColor: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
