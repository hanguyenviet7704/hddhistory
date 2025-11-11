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
    final Color textColor = leadingText.textColor.toHexColor;
    final Color backgroundColor = leadingText.backgroundColor.toHexColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: backgroundColor.op(0.4),
            borderRadius: BorderRadius.circular(20.r),
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
