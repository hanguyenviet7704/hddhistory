part of '../../../roleplay.dart';

class RoleplayIntroTimeChip extends StatelessWidget {
  final String text;

  const RoleplayIntroTimeChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 21, sigmaY: 21),
        child: Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icClock,
                width: 20.w,
                height: 20.w,
                colorFilter: const ColorFilter.mode(AppCustomColor.textWhite, BlendMode.srcIn),
              ),
              8.horizontalSpace,
              AppText(
                text,
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppCustomColor.textWhite,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
