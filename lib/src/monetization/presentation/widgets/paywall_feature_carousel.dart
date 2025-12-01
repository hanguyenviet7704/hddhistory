part of '../../monetization.dart';

class PaywallFeature {
  final String title;
  final String description;
  final IconData icon;

  const PaywallFeature({required this.title, required this.description, required this.icon});
}

class PaywallFeatureCarousel extends StatelessWidget {
  final PageController controller;
  final String title;
  final List<PaywallFeature> items;

  const PaywallFeatureCarousel({
    super.key,
    required this.controller,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppText(
              title,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
            ),
          ),
          12.verticalSpace,
          SizedBox(
            height: 150.h,
            child: PageView.builder(
              controller: controller,
              itemCount: items.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 20.w : 10.w, right: index == items.length - 1 ? 20.w : 10.w),
                  child: _FeatureCard(item: item),
                );
              },
            ),
          ),
          10.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SmoothPageIndicator(
              controller: controller,
              count: items.length,
              effect: ExpandingDotsEffect(
                dotHeight: 6.h,
                dotWidth: 6.h,
                activeDotColor: AppCustomColor.brandPrimary,
                dotColor: AppCustomColor.borderSecondary,
                expansionFactor: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final PaywallFeature item;

  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.op(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundBrand,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(item.icon, color: AppCustomColor.brandPrimary, size: 22.w),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.title,
                  style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                  maxLines: 2,
                ),
                6.verticalSpace,
                AppText(
                  item.description,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
