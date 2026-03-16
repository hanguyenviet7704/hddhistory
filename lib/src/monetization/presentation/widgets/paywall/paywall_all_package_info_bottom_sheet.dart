part of '../../../monetization.dart';

class PaywallAllPackageInfoBottomSheet extends StatelessWidget {
  const PaywallAllPackageInfoBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    AppService.instance.appTrackingService.trackPremiumAllpackScrView();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.bottomSheetScrim,
      routeSettings: const RouteSettings(name: RouteNamed.paywallAllPackageInfoBottomSheet),
      builder: (_) => BlocProvider.value(
        value: context.read<IapCubit>(),
        child: const PaywallAllPackageInfoBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.56,
      minChildSize: 0.56,
      maxChildSize: 0.56,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: BlocBuilder<IapCubit, IapState>(
                builder: (context, state) {
                  final cubit = context.read<IapCubit>();
                  final isLoading = state.status == MonetizationStatus.loading && state.iapProducts.isEmpty;

                  if (isLoading) return _BottomSheetLoading(controller: controller);
                  if (state.iapProducts.isEmpty) return _BottomSheetEmpty(onRetry: cubit.loadIapProducts);

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
              AppText(
                context.l10n.monetization.loadingPlans,
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
        AppText(
          context.l10n.monetization.emptyProductsTitle,
          style: AppStyle.text18.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
        ),
        8.verticalSpace,
        AppText(
          context.l10n.monetization.emptyProductsDesc,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
        ),
        20.verticalSpace,
        Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: const Color(0xFF554FF0),
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(1000.r),
              child: Center(
                child: AppText(
                  context.l10n.monetization.payNowCta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
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
        Row(
          children: [
            const Spacer(),
            AppText(
              context.l10n.monetization.selectPlan,
              style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textTertiary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(Icons.keyboard_double_arrow_down_rounded, color: AppCustomColor.textTertiary, size: 24.w),
            ),
          ],
        ),
        12.verticalSpace,
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final product = products[index];
              final selected = product.id == selectedId || (selectedId.isEmpty && index == 0);
              return PaywallPlanOption(
                product: product,
                selected: selected,
                onTap: () {
                  AppService.instance.appTrackingService.trackPremiumAllpackPick(product.productId);
                  onSelect(product.id);
                },
              );
            },
          ),
        ),
        AppText(
          context.l10n.monetization.paywallHighlightSubtitle,
          textAlign: TextAlign.center,
          style: AppStyle.text12.copyWith(
            fontWeight: FontWeight.w600,
            color: AppCustomColor.textQuaternary,
            height: 1.75,
          ),
        ),
        12.verticalSpace,
        Container(
          width: double.infinity,
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFF554FF0),
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).maybePop();
                AppService.instance.appTrackingService.trackPremiumAllpackPurchase();
                onPurchase();
              },
              borderRadius: BorderRadius.circular(1000.r),
              child: Center(
                child: AppText(
                  context.l10n.monetization.payNowCta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        12.verticalSpace,
      ],
    );
  }
}
