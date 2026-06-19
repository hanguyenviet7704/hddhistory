part of '../../../monetization.dart';

class PaywallLegalLinks extends StatelessWidget {
  const PaywallLegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegalLink(
          label: l10n.auth.termsOfUse,
          url: LegalUrl.termsAndConditions,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          height: 11.h,
          width: 1.w,
          color: AppCustomColor.textBrand.withValues(alpha: 0.2),
        ),
        _LegalLink(
          label: l10n.auth.privacyPolicy,
          url: LegalUrl.privacyPolicy,
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => url.launchURL(),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          fontWeight: FontWeight.w400,
          color: AppCustomColor.textBrand.withValues(alpha: 0.4),
          height: 1.75,
        ),
      ),
    );
  }
}
