part of '../../../roleplay.dart';

class RoleplayHintCard extends StatelessWidget {
  final HintEntity hint;

  const RoleplayHintCard({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: hint.backgroundColor.toHexColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: hint.textColor.toHexColor,
          strokeWidth: 2.w,
          dashPattern: [6.w, 4.w],
          radius: Radius.circular(16.r),
          padding: EdgeInsets.zero,
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                if (hint.icon.isNotEmpty) ...[
                  WidgetSpan(
                    child: DCachedImage(url: hint.icon, height: 16.h),
                  ),
                  WidgetSpan(child: 6.horizontalSpace),
                ],
                TextSpan(
                  text: hint.content.text,
                  style: AppStyle.text14.copyWith(color: hint.textColor.toHexColor, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
