part of '../widgets.dart';

class PremiumUpgradeIntro extends StatelessWidget {
  const PremiumUpgradeIntro({super.key});

  void openPremiumPaywall(BuildContext context) async {
    AppService.instance.appTrackingServiceNew.trackProfileUpgradeClick();
    context.back();
    context.read<PaywallCubit>().setPaywallSource('profile');
    AppService.instance.appTrackingServiceNew.trackPaywallScrView(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PaywallCubit, PaywallState, int>(
      selector: (state) => state.remainingEnergy,
      builder: (context, state) {
        if (state > 100000) {
          return SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppCustomColor.greyEE,
            border: Border(
              top: BorderSide(
                color: AppCustomColor.greyE3,
                width: 2.h,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColorLight.surface,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: SvgPicture.asset(AppAsset.svg.app.icDiamond),
                  ),
                  12.horizontalSpace,
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          context.text.monetPremium,
                          style: AppStyle.textBold18,
                        ),
                        4.verticalSpace,
                        AppText(
                          context.text.monetPremiumPlanAppeal,
                          style: AppStyle.text16,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              12.verticalSpace,
              AppButton.primary(
                onPressed: () => openPremiumPaywall(context),
                fullWidthBtn: true,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(color: AppCustomColor.greyE3),
                  ),
                  color: AppColorLight.surface,
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: AppText(context.text.monetUpgradeFromPrice(miniumValue: '\$4,99'), style: AppStyle.text18),
              ),
            ],
          ),
        );
      },
    );
  }
}
