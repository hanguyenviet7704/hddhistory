part of '../../home.dart';

/// The gold crown disc in the Home header, first of the trailing cluster
/// (design `2 · Home` → `showHome`: Premium / Streak / avatar).
///
/// Lives in `_HeroGreetingRow` (home_hero.dart) — NOT in `HomeHeaderWidget`,
/// which is dead code no route builds.
///
/// Only ever rendered for readers WITHOUT premium — the caller hides it once
/// they subscribe, so this widget has a single visual state like the design.
class HomePremiumChip extends StatelessWidget {
  const HomePremiumChip({super.key});

  static const double _diameter = 28;
  static const double _crownSize = 14;

  void _openPaywall(BuildContext context) {
    AppHaptic.select();
    AppService.instance.appTrackingService.trackHomePremiumClick();
    AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.home);
    const PaywallRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.home.homePremiumLabel,
      child: GestureDetector(
        key: const Key('home-premium-chip'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPaywall(context),
        child: Container(
          width: _diameter.r,
          height: _diameter.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Design: linear-gradient(135deg, #FFD873 0%, #F2B441 100%) — the
            // one gold surface in a header that is otherwise white chips on
            // lavender, which is the whole point of it.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD873), Color(0xFFF2B441)],
            ),
            // `inset 0 0 0 1px rgba(255,255,255,.55)` has no Flutter
            // equivalent; a 1px white border is the same pixel result on this
            // fill, the same substitution StreakHomeChip beside it makes.
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x52BF8A14), // rgba(191,138,20,.32)
                offset: Offset(0, 4.h),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: SvgPicture.asset(
            AppAsset.svg.app.icPremiumCrown,
            width: _crownSize.r,
            height: _crownSize.r,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
