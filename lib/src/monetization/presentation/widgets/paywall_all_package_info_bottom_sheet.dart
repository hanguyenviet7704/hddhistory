part of '../../monetization.dart';

class PaywallAllPackageInfoBottomSheet extends StatelessWidget {
  const PaywallAllPackageInfoBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.bottomSheetScrim,
      builder: (_) => const PaywallAllPackageInfoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: BlocBuilder<IapCubit, IapState>(
              builder: (context, state) {
                final cubit = context.read<IapCubit>();
                final isLoading = state.status == MonetizationStatus.loading && state.iapProducts.isEmpty;

                if (isLoading) {
                  return _BottomSheetLoading(controller: controller);
                }

                if (state.iapProducts.isEmpty) {
                  return _BottomSheetEmpty(onRetry: cubit.loadIapProducts);
                }

                return _BottomSheetContent(
                  controller: controller,
                  products: state.iapProducts,
                  selectedId: state.selectedProductId,
                  onSelect: cubit.setSelectedProductId,
                  onPurchase: cubit.purchaseProduct,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BottomSheetLoading extends StatelessWidget {
  final ScrollController controller;

  const _BottomSheetLoading({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _SheetHandle(),
              16.verticalSpace,
              AppText(
                t.monetization.loadingPlans,
                style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
              ),
              24.verticalSpace,
              const LinearProgressIndicator(minHeight: 3),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomSheetEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _BottomSheetEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SheetHandle(),
        16.verticalSpace,
        AppText(
          t.monetization.emptyProductsTitle,
          style: AppStyle.text18.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
        ),
        8.verticalSpace,
        AppText(
          t.monetization.emptyProductsDesc,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
        ),
        20.verticalSpace,
        AppButton.primary(
          child: t.monetization.retry,
          onPressed: onRetry,
          fullWidthBtn: true,
        ),
      ],
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final ScrollController controller;
  final List<IapProductEntity> products;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;

  const _BottomSheetContent({
    required this.controller,
    required this.products,
    required this.selectedId,
    required this.onSelect,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SheetHandle(),
        12.verticalSpace,
        AppText(
          t.monetization.seeAllPlans,
          style: AppStyle.text16.copyWith(fontWeight: FontWeight.w800, color: AppCustomColor.textPrimary),
        ),
        8.verticalSpace,
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
            itemCount: products.length,
            separatorBuilder: (_, _) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final product = products[index];
              final selected = product.id == selectedId || (selectedId.isEmpty && index == 0);
              return _PackageTile(
                product: product,
                selected: selected,
                onTap: () => onSelect(product.id),
              );
            },
          ),
        ),
        AppButton.primary(
          onPressed: () {
            Navigator.of(context).maybePop();
            onPurchase();
          },
          fullWidthBtn: true,
          child: t.monetization.payNowCta,
        ),
        8.verticalSpace,
        AppButton.secondary(
          onPressed: Navigator.of(context).pop,
          fullWidthBtn: true,
          child: t.monetization.seeLessPlans,
        ),
        8.verticalSpace,
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  final IapProductEntity product;
  final bool selected;
  final VoidCallback onTap;

  const _PackageTile({required this.product, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SelectionDot(selected: selected),
                10.horizontalSpace,
                Expanded(
                  child: AppText(
                    product.title.isNotEmpty ? product.title : t.monetization.paywallTitle,
                    maxLines: 2,
                    style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                  ),
                ),
                if (product.hasDiscount)
                  _SheetBadge(
                    label: t.monetization.saleBadge(percent: product.salePercent),
                    background: AppCustomColor.brandPrimary50,
                    textColor: AppCustomColor.brandPrimary,
                    borderColor: AppCustomColor.brandPrimary,
                  ),
              ],
            ),
            10.verticalSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  product.price,
                  style: AppStyle.text20.copyWith(fontWeight: FontWeight.w800, color: AppCustomColor.textPrimary),
                ),
                8.horizontalSpace,
                AppText(
                  _periodLabel(product),
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                ),
                const Spacer(),
                if (product.hasDiscount)
                  AppText(
                    product.originalPriceString,
                    style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary, decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Icon(Icons.check_circle, color: AppCustomColor.successGreen, size: 18.w),
                6.horizontalSpace,
                Expanded(
                  child: AppText(
                    t.monetization.benefit1Desc,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(IapProductEntity product) {
    final id = product.id.toLowerCase();

    if (id.contains('week')) return t.monetization.pricePerWeek;
    if (id.contains('day')) return t.monetization.pricePerDay;

    return t.monetization.pricePerMonth;
  }
}

class _SheetBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;

  const _SheetBadge({required this.label, required this.background, required this.textColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  final bool selected;

  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.w,
      width: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary, width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: selected ? 10.w : 0,
        width: selected ? 10.w : 0,
        decoration: const BoxDecoration(
          color: AppCustomColor.brandPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppCustomColor.borderSecondary,
          borderRadius: BorderRadius.circular(100.r),
        ),
      ),
    );
  }
}
