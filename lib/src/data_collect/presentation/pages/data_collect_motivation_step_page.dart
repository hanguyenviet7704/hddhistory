part of '../../data_collect.dart';

class DataCollectMotivationStepPage extends StatelessWidget {
  const DataCollectMotivationStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC7C5FA), // Border/Brand
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    Image.asset(
                      width: 245.w,
                      AppAsset.images.common.birdWing.path,
                      fit: BoxFit.contain,
                    ),

                    32.verticalSpace,

                    // Title and subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          AppText(
                            context.text.onboarding.onboardingAfterOnboardEncourageTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: AppStyle.textBold24.copyWith(
                              color: Colors.white, // Text/White
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          AppText(
                            context.text.onboarding.onboardingAfterOnboardEncourageMessage,
                            maxLines: 3,
                            textAlign: TextAlign.center,
                            style: AppStyle.textBold20.copyWith(
                              color: const Color(0xFF362F82), // Brand/Brand/Primary/700
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          12.verticalSpace,
                          // Description
                          AppText(
                            context.text.onboarding.onboardingAfterOnboardEncourageSubText,
                            maxLines: 3,
                            textAlign: TextAlign.center,
                            style: AppStyle.text14.copyWith(
                              color: const Color(0xFF362F82).op(0.6), // Brand/Brand/Primary/700 with 60% opacity
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              width: double.infinity,
              height: 54.h,
              decoration: BoxDecoration(
                color: const Color(0xFF554FF0),
                borderRadius: BorderRadius.circular(1000.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                  DataCollectRoute().go(context);
                },
                  borderRadius: BorderRadius.circular(1000.r),
                  child: Center(
                child: AppText(
                  context.text.onboarding.onboardingSkipGreetingButton,
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
        ),
      ),
    );
  }
}
