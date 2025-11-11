part of '../../../roleplay.dart';

class RoleplayHintCard extends StatelessWidget {
  final HintEntity hint;

  const RoleplayHintCard({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    final Color textColor = hint.textColor.toHexColor == Colors.transparent ? AppCustomColor.grey69 : hint.textColor.toHexColor;

    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: AppCustomColor.roleplayHintBorder,
        strokeWidth: 1.2.w,
        dashPattern: [6.w, 4.w],
        radius: Radius.circular(20.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AppText(
          hint.content,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            color: textColor,
            height: 1.5,
          ),
          maxLines: 4,
        ),
      ),
    );
  }
}
