part of '../monetization.dart';

class PremiumFeatureItem extends StatelessWidget {
  final String icon;
  final String text;

  const PremiumFeatureItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 20.w,
        ),
        12.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            style: AppStyle.text18,
          ),
        ),
      ],
    );
  }
}
