part of '../../onboard.dart';

class ChooseLanguagePage extends StatelessWidget {
  const ChooseLanguagePage({super.key});

  Future<void> _handleSelectLanguage(BuildContext context, AppLocale locale) async {
    context.read<LocaleCubit>().setLocale(locale);
    OnboardIntroduceRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                'Select language',
                style: AppStyle.textBold20.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              24.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: BlocBuilder<LocaleCubit, AppLocale>(
                      builder: (context, state) {
                        return _LanguageOption(
                          flagAsset: AppAsset.svg.common.icUsFlag,
                          languageName: 'English',
                          isSelected: state == AppLocale.en,
                          onTap: () => _handleSelectLanguage(context, AppLocale.en),
                        );
                      },
                    ),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: BlocBuilder<LocaleCubit, AppLocale>(
                      builder: (context, state) {
                        return _LanguageOption(
                          flagAsset: AppAsset.svg.common.icVnFlag,
                          languageName: 'Tiếng Việt',
                          isSelected: state == AppLocale.vi,
                          onTap: () => _handleSelectLanguage(context, AppLocale.vi),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flagAsset;
  final String languageName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flagAsset,
    required this.languageName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary50 : AppCustomColor.borderSecondary,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48.w,
              height: 32.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: SvgPicture.asset(
                flagAsset,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12.h),
            AppText(
              languageName,
              style: AppStyle.textBold16.copyWith(
                color: isSelected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
