part of '../../monetization.dart';

class PaywallPackageList extends StatelessWidget {
  final List<IapProductEntity> products;
  final String selectedProductId;
  final ValueChanged<String> onSelect;
  final VoidCallback onSeeAllPlans;
  final bool loading;
  final Widget emptyPlaceholder;

  const PaywallPackageList({
    super.key,
    required this.products,
    required this.selectedProductId,
    required this.onSelect,
    required this.onSeeAllPlans,
    required this.loading,
    required this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PaywallPackageSkeleton();
    if (products.isEmpty) return emptyPlaceholder;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    context.text.monetization.seeAllPlans,
                    style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllPlans,
                  child: AppText(
                    context.text.monetization.seeAllPlans,
                    style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 210.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final product = products[index];
                final isSelected = product.id == selectedProductId;
                final isMostPopular = index == 0;
                return PaywallPackageCard(
                  product: product,
                  selected: isSelected,
                  onTap: () => onSelect(product.id),
                  showMostPopular: isMostPopular,
                );
              },
              separatorBuilder: (_, _) => 12.horizontalSpace,
              itemCount: products.length,
            ),
          ),
        ],
      ),
    );
  }
}

class PaywallPlansSheet extends StatelessWidget {
  final List<IapProductEntity> products;
  final String selectedProductId;
  final ValueChanged<String> onSelect;

  const PaywallPlansSheet({
    super.key,
    required this.products,
    required this.selectedProductId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      context.text.monetization.seeAllPlans,
                      style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isSelected = product.id == selectedProductId;
                  return PaywallPackageCard(
                    product: product,
                    selected: isSelected,
                    onTap: () => onSelect(product.id),
                    showMostPopular: index == 0,
                  );
                },
                separatorBuilder: (_, _) => 12.verticalSpace,
                itemCount: products.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaywallEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;
  final String retryLabel;

  const PaywallEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      child: Column(
        children: [
          AppText(
            title,
            style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          8.verticalSpace,
          AppText(
            subtitle,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          16.verticalSpace,
          AppButton.secondary(
            onPressed: onRetry,
            child: retryLabel,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ],
      ),
    );
  }
}

class _PaywallPackageSkeleton extends StatelessWidget {
  const _PaywallPackageSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        itemBuilder: (_, _) => Container(
          width: 240.w,
          decoration: BoxDecoration(
            color: AppCustomColor.borderSecondary,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        separatorBuilder: (_, _) => 12.horizontalSpace,
        itemCount: 2,
      ),
    );
  }
}
