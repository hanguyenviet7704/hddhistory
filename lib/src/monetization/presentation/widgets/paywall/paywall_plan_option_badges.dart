part of '../../../monetization.dart';

/// 19px ring with an 11px inner dot when selected, per the paywall design.
class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19.w,
      height: 19.w,
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
              width: 11.w,
              height: 11.w,
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary100,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          fontSize: 12.sp,
          color: AppCustomColor.paywallPromoLabel,
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
