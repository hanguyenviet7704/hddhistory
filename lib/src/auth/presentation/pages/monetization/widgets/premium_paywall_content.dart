part of '../monetization.dart';

class PremiumPaywallContent extends StatelessWidget {
  const PremiumPaywallContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColorLight.surface,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            // Header with close button
            PremiumHeader(
              onClose: () {
                context.back();
                AppService.instance.appTrackingServiceNew.trackPaywallExitClick(context);
              },
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.fromLTRB(140.w, 60.h, 140.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    24.verticalSpace,
                    AppText(
                      context.text.monetUnlockArtlexisPremiumTitle,
                      style: AppStyle.textBold40,
                      textAlign: TextAlign.center,
                    ),
                    20.verticalSpace,
                    // Features list
                    PremiumFeatureItem(
                      icon: AppAsset.svg.app.icLightning,
                      text: context.text.monetPremiumEnergy,
                    ),
                    16.verticalSpace,
                    PremiumFeatureItem(
                      icon: AppAsset.svg.app.icTicket,
                      text: context.text.monetPremiumBooster,
                    ),
                    16.verticalSpace,
                    PremiumFeatureItem(
                      icon: AppAsset.svg.app.icImage,
                      text: context.text.monetPremiumLessonAccess,
                    ),
                    40.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppCustomColor.greyCD, thickness: 1.h),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: AppText(
                            context.text.monetSelectPlan,
                            style: AppStyle.text14,
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppCustomColor.greyCD, thickness: 1.h),
                        ),
                      ],
                    ),
                    16.verticalSpace,

                    BlocBuilder<IAPCubit, IAPState>(
                      builder: (context, state) {
                        return Column(
                          spacing: 24.h,
                          children: List.generate(
                            state.iapProducts.length,
                            (index) => PremiumPlanCard(
                              product: state.iapProducts[index],
                              isSelected: state.selectedProductId == state.iapProducts[index].id,
                              onTap: () {
                                String packageId = state.iapProducts[index].id;
                                context.read<IAPCubit>().setSelectedProductId(packageId);
                                AppService.instance.appTrackingServiceNew.trackPaywallPackageClick(context, packageId);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 140.w, vertical: 24.h),
              child: Column(
                children: [
                  // Subscribe button
                  BlocSelector<IAPCubit, IAPState, bool>(
                    selector: (state) => state.isLoading,
                    builder: (context, isLoading) {
                      return AppButton.primary(
                        onPressed: () {
                          if (isLoading) return;
                          String packageId = context.read<IAPCubit>().state.selectedProductId;
                          AppService.instance.appTrackingServiceNew.trackPaywallStartPremiumClick(context, packageId);
                          context.read<IAPCubit>().purchaseProduct();
                        },
                        fullWidthBtn: true,
                        height: 64.h,
                        borderRadius: BorderRadius.circular(16.r),
                        child: AnimateSwitch(
                          child: (isLoading)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: CircularProgressIndicator(
                                        color: AppColorLight.onPrimary,
                                        strokeWidth: 2.w,
                                      ),
                                    ),
                                    12.horizontalSpace,
                                    AppText(
                                      context.text.monetLoadingPaymentButton,
                                      style: AppStyle.textBold20.copyWith(color: AppColorLight.onPrimary),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(AppAsset.svg.app.icMultiStar),
                                    8.horizontalSpace,
                                    AppText(
                                      context.text.monetStartPremium,
                                      style: AppStyle.textBold20.copyWith(color: AppColorLight.onPrimary),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),

                  16.verticalSpace,

                  AppText(
                    context.text.monetCancelAnytime,
                    style: AppStyle.textBold18.copyWith(color: AppCustomColor.grey69),
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
