// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../monetization.dart';

class PremiumPlanCard extends StatelessWidget {
  final IapProduct product;
  final bool isSelected;
  final VoidCallback? onTap;

  const PremiumPlanCard({
    super.key,
    this.product = const IapProduct(),
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColorLight.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? AppCustomColor.orangeEC : AppCustomColor.greyE3,
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? AppCustomColor.orangeEC : AppCustomColor.greyE3,
                  offset: Offset(0, 4.h),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  product.title,
                  style: AppStyle.textBold20,
                ),
                4.verticalSpace,
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '${product.price} ', style: AppStyle.textBold24),
                      if (product.isSale)
                        TextSpan(
                          text: product.originalPriceString,
                          style: AppStyle.text20.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppCustomColor.grey69,
                          ),
                        ),
                      TextSpan(
                        text: ' /${product.period(context)}',
                        style: AppStyle.text20.copyWith(
                          color: AppCustomColor.grey69,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (product.isSale)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.orangeEC,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: AppText(
                  context.text.monetSavePercent,
                  style: AppStyle.textBold16.copyWith(color: AppColorLight.surface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
