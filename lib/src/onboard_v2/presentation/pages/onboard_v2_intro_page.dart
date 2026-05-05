part of '../../onboard_v2.dart';

class OnboardV2IntroPage extends StatelessWidget {
  const OnboardV2IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2P1GetStartedCta,
        onPressed: context.read<OnboardV2Cubit>().continueFromIntro,
      ),
      child: Column(
        children: [
          58.verticalSpace,
          const _OnboardV2IntroCarousel(),
          48.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P1TitlePrefix,
            textAlign: TextAlign.center,
            style: AppStyle.text32.copyWith(
              color: AppCustomColor.brandPrimary,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          OnboardV2GradientText(
            onboardingL10n.onboardingV2P1TitleBrand,
            textAlign: TextAlign.center,
            style: AppStyle.text32.copyWith(fontWeight: FontWeight.w800, height: 1.25),
          ),
          16.verticalSpace,
          AppText(
            '${onboardingL10n.onboardingV2P1SubtitleLine1}\n${onboardingL10n.onboardingV2P1SubtitleLine2}',
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _OnboardV2IntroCarousel extends StatelessWidget {
  const _OnboardV2IntroCarousel();

  static final _cards = [
    AppAsset.images.app.onboardExploreDeco.path,
    AppAsset.images.app.onboardConnectDecor.path,
    AppAsset.images.app.onboardFeelDecor.path,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _card(_cards[0], x: -84.w, angle: -0.16, scale: 0.82),
          _card(_cards[2], x: 84.w, angle: 0.16, scale: 0.82),
          _card(_cards[1], x: 0, angle: 0, scale: 1),
        ],
      ),
    );
  }

  Widget _card(String asset, {required double x, required double angle, required double scale}) {
    return Transform.translate(
      offset: Offset(x, 0),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 148.w,
            height: 180.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppCustomColor.borderDefault),
              boxShadow: const [BoxShadow(color: Color(0x24211B40), blurRadius: 24, offset: Offset(0, 12))],
            ),
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
