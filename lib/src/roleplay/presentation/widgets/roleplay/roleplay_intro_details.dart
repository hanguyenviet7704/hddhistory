part of '../../../roleplay.dart';

class RoleplayIntroDetails extends StatelessWidget {
  final String title;
  final String duration;
  final String description;

  const RoleplayIntroDetails({
    super.key,
    required this.title,
    required this.duration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: AppStyle.text32.copyWith(
            fontWeight: FontWeight.w700,
            color: AppCustomColor.textWhite,
            height: 40 / 32,
          ),
        ),
        12.verticalSpace,
        if (duration.isNotEmpty)
          AppText(
            duration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textWhite,
              letterSpacing: 0.2,
            ),
          ),
        12.verticalSpace,
        AppText(
          description,
          maxLines: 6,
          textAlign: TextAlign.center,
          style: AppStyle.text16.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}
