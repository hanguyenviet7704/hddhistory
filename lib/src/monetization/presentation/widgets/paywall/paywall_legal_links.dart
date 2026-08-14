part of '../../../monetization.dart';

class PaywallLegalLinks extends StatelessWidget {
  /// The compact sheet's footer: one line, dot-separated, a size down — and it
  /// carries Restore, which on that surface has nowhere else to live (the full
  /// page has its own Restore row underneath these links).
  final bool compact;
  final VoidCallback? onRestore;

  const PaywallLegalLinks({
    super.key,
    this.compact = false,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final terms = _LegalLink(
      label: l10n.auth.termsOfUse,
      url: LegalUrl.termsAndConditions,
      compact: compact,
      onTrack: () => AppService.instance.appTrackingService.trackPaywallTermsClick(),
    );
    final privacy = _LegalLink(
      label: l10n.auth.privacyPolicy,
      url: LegalUrl.privacyPolicy,
      compact: compact,
      onTrack: () => AppService.instance.appTrackingService.trackPaywallPrivacyClick(),
    );

    if (!compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          terms,
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            height: 14.h,
            width: 1.w,
            color: const Color(0xFFCFCBDD),
          ),
          privacy,
        ],
      );
    }

    // Wrap, not Row: three Vietnamese labels don't fit one line on a 390-wide
    // sheet (RIGHT OVERFLOWED BY 89 PIXELS) — English does, so the overflow only
    // showed on vi. Each dot rides WITH the link before it, so a line break
    // never opens with an orphaned separator.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 2.h,
      children: [
        if (onRestore != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptic.select();
                  AppService.instance.appTrackingService.trackPremiumRestoreClick();
                  onRestore!();
                },
                child: AppText(
                  l10n.monetization.restore,
                  maxLines: 1,
                  style: _compactStyle,
                ),
              ),
              _dot,
            ],
          ),
        Row(mainAxisSize: MainAxisSize.min, children: [terms, _dot]),
        privacy,
      ],
    );
  }

  static TextStyle get _compactStyle => AppStyle.text12.copyWith(
    fontSize: 12.5.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFA8A2C6),
    height: 1.4,
  );

  Widget get _dot => Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    child: AppText('•', maxLines: 1, style: _compactStyle),
  );
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  final bool compact;
  final VoidCallback onTrack;

  const _LegalLink({
    required this.label,
    required this.url,
    required this.onTrack,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptic.select();
        onTrack();
        url.launchURL();
      },
      child: AppText(
        label,
        maxLines: 1,
        style: compact
            ? PaywallLegalLinks._compactStyle
            : AppStyle.text14.copyWith(
                fontWeight: FontWeight.w500,
                color: AppCustomColor.paywallCtaCaption,
                height: 1.4,
              ),
      ),
    );
  }
}
