part of '../../monetization.dart';

class PaywallBenefitItem {
  final String title;
  final String description;

  const PaywallBenefitItem({required this.title, required this.description});
}

class PaywallBenefitSection extends StatelessWidget {
  const PaywallBenefitSection({super.key, required this.title, required this.benefits});

  final String title;
  final List<PaywallBenefitItem> benefits;

  @override
  Widget build(BuildContext context) {
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,
        Column(
          children: benefits
              .map(
                (benefit) => Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColorLight.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppCustomColor.borderSecondary),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: AppCustomColor.brandPrimary50,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: AppAsset.icons.app.icTick.image(
                          width: 16.w,
                          height: 16.w,
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              benefit.title,
                              maxLines: 2,
                              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                            ),
                            6.verticalSpace,
                            AppText(
                              benefit.description,
                              maxLines: 4,
                              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
