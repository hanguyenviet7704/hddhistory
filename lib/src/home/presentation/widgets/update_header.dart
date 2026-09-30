part of '../../home.dart';

/// Update header pinned at the top of Home (design "Update Header" — the
/// `app:home` top cover-sheet). This is the app's ONLY update surface: shown
/// whenever a NEWER version exists for the platform, forced or not (the blocking
/// splash dialog was removed). Solid brand cover-sheet with rounded bottom
/// corners, an icon chip, a two-line message and a white "Update" pill. Tapping
/// Update opens the platform store and dismisses the banner for the session (it
/// reappears next launch until the user actually updates).
class UpdateHeader extends StatelessWidget {
  const UpdateHeader({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  /// Design brand indigo (#554FF0) — the cover-sheet fill (NOT a gradient).
  static const Color _brand = Color(0xFFB5860F);

  void _handleUpdatePressed() {
    try {
      // Mirror SplashPage._handleUpdatePressed store URLs + open pattern.
      final String storeUrl = Platform.isIOS ? 'https://apps.apple.com/us/app/meup-up-your-skills/id6755175330' : 'https://play.google.com/store/apps/details?id=com.eup.meup';
      storeUrl.launchURL();
    } catch (e) {
      LogDev.error('UpdateHeader: error launching app store: $e');
    }
    // Dismiss regardless — the store has been handed off; the banner returns
    // next launch until the installed version is actually newer.
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final homeL10n = context.l10n.home;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22.r)),
        boxShadow: [
          BoxShadow(color: _brand.withValues(alpha: 0.34), blurRadius: 30.r, offset: Offset(0, 12.h)),
        ],
      ),
      child: Row(
        children: [
          // Icon chip — 36×36 translucent-white rounded square with an inset border.
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppCustomColor.textWhite.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: AppCustomColor.textWhite.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.arrow_upward_rounded, color: AppCustomColor.textWhite, size: 19.w),
          ),
          11.horizontalSpace,
          // Two-line message.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  homeL10n.updateBannerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.textBold14.copyWith(color: AppCustomColor.textWhite, height: 1.2),
                ),
                2.verticalSpace,
                AppText(
                  homeL10n.updateBannerSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.text12.copyWith(color: AppCustomColor.textWhite.withValues(alpha: 0.85), height: 1.35),
                ),
              ],
            ),
          ),
          11.horizontalSpace,
          // White "Update" pill.
          Semantics(
            button: true,
            label: homeL10n.updateBannerAction,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                _handleUpdatePressed();
              },
              child: Container(
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppCustomColor.textWhite,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: AppText(
                  homeL10n.updateBannerAction,
                  maxLines: 1,
                  style: AppStyle.textBold12.copyWith(color: _brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
