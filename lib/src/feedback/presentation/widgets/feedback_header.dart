part of '../../feedback.dart';

class FeedbackHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const FeedbackHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText(
          title,
          textAlign: TextAlign.center,
          enableFitScaleDown: true,
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w700,
            color: AppCustomColor.textWhite,
            height: 1.5,
          ),
        ),
        if (subtitle != null) ...[
          4.verticalSpace,
          AppText(
            subtitle!,
            textAlign: TextAlign.center,
            enableFitScaleDown: true,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textWhite.op(0.7),
              height: 1.75,
            ),
          ),
        ],
      ],
    );
  }
}
