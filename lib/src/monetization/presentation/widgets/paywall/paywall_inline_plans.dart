part of '../../../monetization.dart';

class _PaywallInlinePlans extends StatelessWidget {
  final IapState state;
  final ValueChanged<IapProductEntity> onPlanTap;

  const _PaywallInlinePlans({
    required this.state,
    required this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == MonetizationStatus.loading && state.iapProducts.isEmpty;
    if (isLoading) return const _InlinePlanLoading();
    if (state.iapProducts.isEmpty) return const _InlinePlanEmpty();

    return Column(
      children: [
        for (var index = 0; index < state.iapProducts.length; index++) ...[
          if (index > 0) 12.verticalSpace,
          PaywallPlanOption(
            product: state.iapProducts[index],
            selected: state.iapProducts[index].id == state.selectedProductId,
            onTap: () => onPlanTap(state.iapProducts[index]),
          ),
        ],
      ],
    );
  }
}

class _InlinePlanLoading extends StatelessWidget {
  const _InlinePlanLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 2; index++) ...[
          if (index > 0) 12.verticalSpace,
          Container(
            height: 84.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F1FE),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppCustomColor.borderSecondary),
            ),
            child: const Center(child: LinearProgressIndicator(minHeight: 2)),
          ),
        ],
      ],
    );
  }
}

class _InlinePlanEmpty extends StatelessWidget {
  const _InlinePlanEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F1FE),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderBrand),
      ),
      child: Column(
        children: [
          AppText(
            l10n.monetization.emptyProductsTitle,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
          ),
          6.verticalSpace,
          AppText(
            l10n.monetization.emptyProductsDesc,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text12.copyWith(color: AppCustomColor.textSecondary, height: 1.7),
          ),
        ],
      ),
    );
  }
}
