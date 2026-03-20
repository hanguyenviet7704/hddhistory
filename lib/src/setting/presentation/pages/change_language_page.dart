part of '../../setting.dart';

class ChangeLanguagePage extends StatefulWidget {
  const ChangeLanguagePage({super.key});

  @override
  State<ChangeLanguagePage> createState() => _ChangeLanguagePageState();
}

class _ChangeLanguagePageState extends State<ChangeLanguagePage> {
  static const List<AppLocale> _displayLocales = [AppLocale.en, AppLocale.vi];
  bool _hasTrackedView = false;

  void _handleSelectLanguage(BuildContext context, AppLocale locale) {
    context.read<LocaleCubit>().setLocale(locale);
    context.back();
  }

  void _trackView() {
    if (_hasTrackedView) return;
    final locale = context.read<LocaleCubit>().state;
    AppService.instance.appTrackingService.trackSettingLanguageScrView(locale.languageAISupport);
    _hasTrackedView = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return CupertinoScaffold(
      topRadius: const Radius.circular(24),
      transitionBackgroundColor: AppCustomColor.backgroundWhite,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            12.verticalSpace,
            Container(
              width: 56.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppCustomColor.textQuaternary,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            12.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _LanguageSheetBackButton(onPressed: () => context.pop()),
                  ),
                  Text(
                    context.l10n.setting.settingRowLanguage,
                    style: AppStyle.text16.copyWith(
                      color: AppCustomColor.textTertiary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppCustomColor.borderDefault),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
              child: BlocBuilder<LocaleCubit, AppLocale>(
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
                        if (index < _displayLocales.length - 1) 16.verticalSpace,
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
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
