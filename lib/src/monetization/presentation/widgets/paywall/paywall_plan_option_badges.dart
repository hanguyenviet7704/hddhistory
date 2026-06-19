part of '../../../monetization.dart';

class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF4B44CA) : AppCustomColor.borderDefault,
          width: selected ? 6.w : 2.w,
        ),
        color: AppCustomColor.backgroundWhite,
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String label;

  const _DiscountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text10.copyWith(
          color: AppCustomColor.brandPrimary900,
          fontWeight: FontWeight.w700,
          height: 1.75,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.paywallBestDeal,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text10.copyWith(
          fontWeight: FontWeight.w700,
          color: AppCustomColor.textPrimary,
          height: 1.75,
        ),
      ),
    );
  }
}
