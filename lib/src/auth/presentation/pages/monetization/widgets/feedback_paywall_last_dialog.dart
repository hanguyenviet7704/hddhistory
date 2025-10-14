part of '../monetization.dart';

class FeedbackPaywallLastDialog extends StatefulWidget {
  const FeedbackPaywallLastDialog({
    super.key,
  });

  @override
  State<FeedbackPaywallLastDialog> createState() => _FeedbackPaywallLastDialogState();
}

class _FeedbackPaywallLastDialogState extends State<FeedbackPaywallLastDialog> {
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
                        Container(
                          padding: const EdgeInsets.only(top: 8, left: 12, right: 16, bottom: 8),
                          decoration: ShapeDecoration(
                            color: AppCustomColor.blueEF,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: AppCustomColor.blueD1,
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
                              AppAsset.images.imgFirecracker.image(
                                width: 24.w,
                                height: 24.w,
                              ),
                              AppText(
                                context.text.roadmapAfterFeedbackPopupBadge,
                                textAlign: TextAlign.center,
                                style: AppStyle.textBold20.copyWith(
                                  color: AppCustomColor.blue19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        12.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                context.text.roadmapAfterFeedbackPopupMessage,
                                style: AppStyle.textBold32,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        64.verticalSpace,
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
                    _onTrackingFeedbackExitEvent();
                    context.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTrackingFeedbackExitEvent() {
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.feedback3ThankExit,
      parameters: TrackingParams.withDrawTopic(),
    );
  }
}
