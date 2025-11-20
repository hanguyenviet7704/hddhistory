part of '../../setting.dart';

class ChangeLanguagePage extends StatelessWidget {
  const ChangeLanguagePage({super.key});

  static const List<LocaleType> _displayLocales = [LocaleType.en, LocaleType.vi];

  void _handleSelectLanguage(BuildContext context, LocaleType locale) {
    context.read<LocaleCubit>().changeLocale(locale);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding + 12.h),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            child: Container(
              width: double.infinity,
              color: AppCustomColor.backgroundWhite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _LanguageSheetBackButton(onPressed: () => context.pop()),
                        ),
                        Text(
                          context.text.settingRowLanguage,
                          style: AppStyle.text16.copyWith(
                            color: AppCustomColor.textTertiary,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppCustomColor.borderDefault),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                    child: BlocBuilder<LocaleCubit, LocaleType>(
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int index = 0; index < _displayLocales.length; index++) ...[
                              ChangeLanguageOptionTile(
                                locale: _displayLocales[index],
                                isSelected: state == _displayLocales[index],
                                onTap: () => _handleSelectLanguage(context, _displayLocales[index]),
                              ),
                              if (index < _displayLocales.length - 1) SizedBox(height: 16.h),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSheetBackButton extends StatelessWidget {
  const _LanguageSheetBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36.w,
      height: 36.w,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 20.w,
        icon: Icon(Icons.arrow_back_ios_new, color: AppCustomColor.textTertiary, size: 18.w),
        onPressed: onPressed,
      ),
    );
  }
}
