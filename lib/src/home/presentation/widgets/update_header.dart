part of '../../home.dart';

/// Optional-update header banner pinned at the top of Home (design "Update
/// Header"). Shown only when a NEWER, non-forced app version exists — the
/// forced-update case is handled separately by the blocking splash dialog
/// ([ForceUpdateContent]). A slim brand-gradient bar with white content;
/// tapping "Update" opens the platform store and dismisses the banner for the
/// session (it reappears next launch until the user actually updates).
class UpdateHeader extends StatelessWidget {
  const UpdateHeader({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  /// Brand gradient from the new logo (design): #8B8BF0 → #4B45D6.
  static const Color _gradientStart = Color(0xFF8B8BF0);
  static const Color _gradientEnd = Color(0xFF4B45D6);

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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_alt,
            color: AppCustomColor.textWhite,
            size: 20.w,
          ),
          10.horizontalSpace,
          Expanded(
            child: AppText(
              context.l10n.home.updateBannerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.textBold14.copyWith(
                color: AppCustomColor.textWhite,
              ),
            ),
          ),
          10.horizontalSpace,
          Semantics(
            button: true,
            label: context.l10n.home.updateBannerAction,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                _handleUpdatePressed();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.textWhite,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: AppText(
                  context.l10n.home.updateBannerAction,
                  maxLines: 1,
                  style: AppStyle.textBold12.copyWith(
                    fontSize: 13.sp,
                    color: AppCustomColor.brandPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
