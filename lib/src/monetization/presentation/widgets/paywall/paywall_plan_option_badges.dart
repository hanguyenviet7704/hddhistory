part of '../../../monetization.dart';

/// 19px ring with an 11px inner dot when selected, per the paywall design.
class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    // Design `6b · Premium`: an 18 ring with a 9 dot. It shipped at 19/11,
    // which made the radio the heaviest mark on the card.
    return Container(
      width: 18.w,
      height: 18.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppCustomColor.paywallPromoLabel : AppCustomColor.borderDefault,
          width: 2.w,
        ),
        color: AppCustomColor.backgroundWhite,
      ),
      child: selected
          ? Container(
              width: 9.w,
              height: 9.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppCustomColor.paywallPromoLabel,
              ),
            )
          : null,
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String label;

  const _DiscountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Design `6b · Premium`: a YELLOW chip, not the lavender one it used to
      // be. Literal hex rather than a theme token on purpose — this is the one
      // warm accent on an otherwise violet screen, and the brand palette has no
      // slot for it (same call as _kFacebookBrandBlue).
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D31A),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          fontSize: 9.sp,
          color: const Color(0xFF4A2A17),
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _BestDealBadge extends StatelessWidget {
  final String label;

  const _BestDealBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppCustomColor.paywallBestDeal,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text10.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.44,
          color: AppCustomColor.textBrand,
          height: 1.2,
        ),
      ),
    );
  }
}
