part of '../../onboard.dart';

class IntroHeader extends StatelessWidget {
  final VoidCallback onLanguageTap;

  const IntroHeader({super.key, required this.onLanguageTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: GestureDetector(
          onTap: onLanguageTap,
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(color: AppCustomColor.borderDefault, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<LocaleCubit, AppLocale>(
                  builder: (context, locale) {
                    return SvgPicture.asset(locale.flagCircle, width: 24.w, height: 16.h, fit: BoxFit.cover);
                  },
                ),
                10.horizontalSpace,
                BlocBuilder<LocaleCubit, AppLocale>(
                  builder: (context, locale) {
                    return AppText(
                      locale.label,
                      style: AppStyle.text14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppCustomColor.textPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
