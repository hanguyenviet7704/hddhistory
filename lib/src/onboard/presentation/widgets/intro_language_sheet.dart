part of '../../onboard.dart';

class IntroLanguageSheet extends StatelessWidget {
  final AppLocale selectedLocale;
  final ValueChanged<AppLocale> onSelected;

  const IntroLanguageSheet({
    super.key,
    required this.selectedLocale,
    required this.onSelected,
  });

  static Future<void> show(BuildContext context, {String? source}) async {
    if (source != null && source.isNotEmpty) {
      AppService.instance.appTrackingService.trackObdLanguagePopupView(source);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (sheetContext) {
        final selectedLocale = sheetContext.read<LocaleCubit>().state;

        return IntroLanguageSheet(
          selectedLocale: selectedLocale,
          onSelected: (locale) {
            context.read<LocaleCubit>().setLocale(locale);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomInset + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            context.l10n.setting.settingRowLanguage,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textTertiary,
              height: 1.5,
            ),
          ),
          16.verticalSpace,
          ...AppLocaleX.displayLocales.map(
            (locale) => Padding(
              padding: EdgeInsets.only(bottom: locale == AppLocaleX.displayLocales.last ? 0 : 12.h),
              child: _LanguageTile(
                locale: locale,
                isSelected: locale == selectedLocale,
                onTap: () {
                  onSelected(locale);
                  context.back();
                },
              ),
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
      onTap: () {
        AppService.instance.appTrackingService.trackObdLanguageClick(locale.languageAISupport);
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText(
                locale.label,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppCustomColor.textPrimary : AppCustomColor.textSecondary,
                ),
              ),
            ),
            SvgPicture.asset(locale.flagCircle, width: 32.w, height: 24.h, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
}
