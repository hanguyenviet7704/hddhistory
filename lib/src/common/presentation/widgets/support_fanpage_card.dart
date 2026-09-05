part of '../../common.dart';

/// The single support channel the app points people at. Numeric `profile.php`
/// form because the page has no vanity username yet — keep it as-is rather than
/// "tidying" it into a /name path, which would 404.
const _kSupportFanpageUrl = 'https://www.facebook.com/profile.php?id=61586812343588';

/// Facebook's own brand blue. Deliberately a literal and NOT a theme token: it
/// identifies someone else's product, so it must not shift with our palette or
/// with the user's study theme.
const _kFacebookBrandBlue = Color(0xFF1877F2);

/// Inlined rather than added to `assets/` — it is a single one-off brand mark,
/// the same way the profile rows carry their glyphs as strings.
const _kFacebookGlyphSvg = '''
<svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.77-3.89 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.45 2.89h-2.33v6.99A10 10 0 0 0 22 12z" fill="#ffffff"/>
</svg>
''';

/// "Support" block: the section heading plus one row that opens the MeUp
/// fanpage in the system browser.
///
/// Lives in `common` rather than in the profile feature because Profile and
/// Home both render it — one definition is what keeps the two from drifting
/// apart the first time the copy or the channel changes.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.setting.settingSupportFanpageTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same label treatment as every other section on the merged Settings
        // screen (see SettingSectionCard) — this used to be a 20/700 page
        // heading because it was one of two on the old Profile screen, and at
        // that size it now shouts over the four quiet labels around it.
        AppText(
          context.l10n.setting.settingProfileSupportSection,
          style: AppStyle.text14.copyWith(
            color: studyThemeOnBg(context, AppCustomColor.textTertiary),
          ),
        ),
        12.verticalSpace,
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D252525),
                offset: Offset(0, 6.h),
                blurRadius: 18.r,
              ),
            ],
          ),
          child: Semantics(
            button: true,
            label: title,
            child: GestureDetector(
              key: const Key('support-fanpage-row'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                _kSupportFanpageUrl.launchURL();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: const BoxDecoration(
                        color: _kFacebookBrandBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.string(
                        _kFacebookGlyphSvg,
                        width: 26.w,
                        height: 26.w,
                      ),
                    ),
                    14.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            title,
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppCustomColor.textPrimary,
                            ),
                          ),
                          2.verticalSpace,
                          AppText(
                            context.l10n.setting.settingSupportFanpageSubtitle,
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: studyThemeCardMuted(
                                context,
                                AppCustomColor.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Signals "leaves the app", which a chevron would not.
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 20.w,
                      color: _kFacebookBrandBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
