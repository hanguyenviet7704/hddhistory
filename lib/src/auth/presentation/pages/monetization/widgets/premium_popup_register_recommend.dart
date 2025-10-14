part of '../monetization.dart';

class PremiumPopupRegisterRecommend extends StatelessWidget {
  const PremiumPopupRegisterRecommend({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.text.close,
      transitionBuilder: (_, animation, _, child) {
        final curved = Curves.easeOutBack.transform(animation.value);
        return Transform.scale(
          scale: curved,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => const PremiumPopupRegisterRecommend(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: 620.w,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFF1B491).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with title and close button
                  Image.asset(
                    AppAsset.images.userPurchaseDecoration.path,
                    width: 720.w,
                  ),
                  32.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        LimitCard(),
                        12.verticalSpace,
                        AppText(
                          context.text.monetPopupLogInToClaimEnergyTitle,
                          style: AppStyle.textBold32,
                        ),
                        24.verticalSpace,
                        AppText(
                          context.text.monetPopupLogInToClaimEnergyBody,
                          style: AppStyle.text20.copyWith(
                            color: AppCustomColor.grey69,
                          ),
                        ),

                        60.verticalSpace,
                        // Action buttons
                        AppButton.primary(
                          width: 324.w,
                          child: BonusGift(),
                          onPressed: () async {
                            AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder1Click(context, true);
                            context.back();
                            await LoginRoute(isRegister: true).push(context);
                            AppDI.injector.get<PaywallCubit>().showFeedbackPaywallDialog();
                          },
                        ),
                        24.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20.w,
                right: 20.w,
                child: CloseOverlayButton(
                  onPressed: () {
                    AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder1Click(context, false);
                    context.back();
                    AppDI.injector.get<PaywallCubit>().showFeedbackPaywallDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LimitCard extends StatelessWidget {
  const LimitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 16, bottom: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFF4EA) /* Primary-50 */,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFFFCD9B3) /* Primary-200 */,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 12.w,
        children: [
          SvgPicture.asset(
            AppAsset.svg.app.icGift,
            width: 32.w,
            // height: 32.w,
          ),
          AppText(
            context.text.monetPopupLogInToClaimEnergyLabel,
            textAlign: TextAlign.center,
            style: AppStyle.textBold20.copyWith(
              color: AppCustomColor.red4D,
            ),
          ),
        ],
      ),
    );
  }
}

class BonusGift extends StatelessWidget {
  const BonusGift({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          context.text.monetPopupLogInToClaimEnergyButton,
          textAlign: TextAlign.center,
          style: AppStyle.textBold20.copyWith(color: AppColorLight.onPrimary),
        ),
        12.horizontalSpace,
        Container(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: ShapeDecoration(
            color: Colors.white /* Color */,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(42),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 3,
            children: [
              AppText(
                '+ 10',
                textAlign: TextAlign.center,
                style: AppStyle.textBold20,
              ),
              Image.asset(AppAsset.icons.thunder.path),
            ],
          ),
        ),
      ],
    );
  }
}
