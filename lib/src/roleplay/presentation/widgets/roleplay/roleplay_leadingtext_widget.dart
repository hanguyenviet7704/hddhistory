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
    final bool hasBackground = backgroundColor.opacity > 0.05;
    final double effectiveOpacity = (backgroundColor.opacity.clamp(0.12, 0.6) as double);

    Widget content = AppText(
      leadingText.content.text,
      textAlign: TextAlign.center,
      style: AppStyle.text12.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
        height: 1.75,
      ),
      maxLines: 20,
    );

    if (!hasBackground) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (audioController?.hasAudio ?? false) ...[
              12.verticalSpace,
              RoleplayAudioButton(
                controller: audioController,
                iconColor: textColor,
              ),
            ],
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(effectiveOpacity),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              if (audioController?.hasAudio ?? false) ...[
                16.verticalSpace,
                RoleplayAudioButton(
                  controller: audioController,
                  iconColor: textColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
