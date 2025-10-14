part of '../../auth.dart';

class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(icon, width: 60.w, height: 60.w),
          8.verticalSpace,
          AppText(title, style: AppStyle.textBold24),
          8.verticalSpace,
          AppText(description, style: AppStyle.text20, maxLines: 10),
        ],
      ),
    );
  }
}
