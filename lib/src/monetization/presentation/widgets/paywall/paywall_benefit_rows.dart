part of '../../../monetization.dart';

class _PaywallRemoteBenefitRow extends StatelessWidget {
  final PaywallBenefitEntity benefit;
  final AssetGenImage fallbackAsset;

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
              width: 32.w,
              height: 32.w,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => _fallbackIcon(),
              placeholder: (_, _) => _fallbackIcon(),
            ),
      text: benefit.title.text,
    );
  }

  Widget _fallbackIcon() => Image.asset(
    fallbackAsset.path,
    width: 32.w,
    height: 32.w,
    fit: BoxFit.contain,
  );
}

class _PaywallLocalBenefitRow extends StatelessWidget {
  final AssetGenImage asset;
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
      icon: Image.asset(asset.path, width: 32.w, height: 32.w, fit: BoxFit.contain),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32.w,
          height: 32.w,
          child: Center(child: icon),
        ),
        12.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textBrand,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}
