part of '../../../monetization.dart';

class _PaywallRemoteBenefitRow extends StatelessWidget {
  final PaywallBenefitEntity benefit;
  /// Path of an SVG in assets/svg/app, used when the remote icon is absent.
  final String fallbackAsset;

  const _PaywallRemoteBenefitRow({
    required this.benefit,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final iconUrl = benefit.icon.text;
    return _BenefitRowShell(
      icon: iconUrl.isEmpty
          ? _fallbackIcon()
          : CachedNetworkImage(
              imageUrl: iconUrl,
              width: 28.w,
              height: 28.w,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => _fallbackIcon(),
              placeholder: (_, _) => _fallbackIcon(),
            ),
      text: benefit.title.text,
    );
  }

  Widget _fallbackIcon() => SvgPicture.asset(
    fallbackAsset,
    width: 28.w,
    height: 28.w,
    fit: BoxFit.contain,
  );
}

class _PaywallLocalBenefitRow extends StatelessWidget {
  final String asset;
  final String title;
  final String description;

  const _PaywallLocalBenefitRow({
    required this.asset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _BenefitRowShell(
      icon: SvgPicture.asset(asset, width: 28.w, height: 28.w, fit: BoxFit.contain),
      text: '$title $description',
    );
  }
}

class _BenefitRowShell extends StatelessWidget {
  final Widget icon;
  final String text;

  const _BenefitRowShell({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28.w,
          height: 28.w,
          child: Center(child: icon),
        ),
        14.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textBrand,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
