part of '../../onboard.dart';

class IntroLanguageSheet extends StatelessWidget {
  final AppLocale selectedLocale;
  final ValueChanged<AppLocale> onSelected;

  const IntroLanguageSheet({super.key, required this.selectedLocale, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 20.h,
        top: 12.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppCustomColor.borderSecondary,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          16.verticalSpace,
          AppText(
            context.text.setting.settingRowLanguage,
            style: AppStyle.text18.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textPrimary,
            ),
          ),
          16.verticalSpace,
          ...AppLocale.values.map(
            (locale) => _LanguageTile(
              locale: locale,
              isSelected: locale == selectedLocale,
              onTap: () {
                onSelected(locale);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLocale locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({required this.locale, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary50 : AppCustomColor.borderSecondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(locale.flagCircle, width: 32.w, height: 32.h),
            12.horizontalSpace,
            Expanded(
              child: AppText(
                locale.label,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: AppCustomColor.brandPrimary,
                size: 20.w,
              ),
          ],
        ),
      ),
    );
  }
}
