part of '../../../course.dart';

class LessonMetadata extends StatelessWidget {
  final TagEntity? icon;
  final String text;
  final Color? textColor;

  const LessonMetadata({
    super.key,
    this.icon,
    required this.text,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && icon!.url.isNotEmpty)
          CacheNetworkGraphic(
            url: icon!.url,
            width: 16.w,
            height: 16.h,
            color: textColor,
          ),
        if (icon != null && icon!.url.isNotEmpty) 4.horizontalSpace,
        AppText(
          text,
          style: AppStyle.text12.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor ?? AppCustomColor.textSecondary,
          ),
        ),
      ],
    );
  }
}
