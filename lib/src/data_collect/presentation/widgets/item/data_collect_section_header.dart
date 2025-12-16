part of '../../../data_collect.dart';

class DataCollectSectionHeader extends StatelessWidget {
  const DataCollectSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.note,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final String? subtitle;
  final String? note;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (note != null) ...[
          AppText(
            note!,
            textAlign: textAlign,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.brandPrimary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          8.verticalSpace,
        ],
        AppText(
          title,
          textAlign: textAlign,
          style: AppStyle.textBold20.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
          maxLines: 3,
        ),
        if (subtitle != null) ...[
          8.verticalSpace,
          AppText(
            subtitle!,
            textAlign: textAlign,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              height: 1.6,
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }
}
