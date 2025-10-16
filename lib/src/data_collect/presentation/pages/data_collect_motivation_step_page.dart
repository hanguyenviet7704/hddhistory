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
            // Status bar space
            SizedBox(height: 59.h),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    SizedBox(
                      height: 239.h,
                      width: 245.w,
                      child: Image.asset(
                        'assets/images/common/bird_happy.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Title and subtitle
                    Column(
                      children: [
                        AppText(
                          "You're not alone!",
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold24.copyWith(
                            color: Colors.white, // Text/White
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          "72% of our users shared the same response",
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold20.copyWith(
                            color: const Color(0xFF362F82), // Brand/Brand/Primary/700
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Description
                    AppText(
                      "Start today and become a better version of yourself through your voice",
                      textAlign: TextAlign.center,
                      style: AppStyle.text14.copyWith(
                        color: const Color(0xFF362F82).withOpacity(0.6), // Brand/Brand/Primary/700 with 60% opacity
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Button
            Container(
              padding: EdgeInsets.all(20.w),
              child: AppButton.primary(
                onPressed: () {
                  DataCollectRoute().go(context);
                },
                fullWidthBtn: true,
                height: 54.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF554FF0), // Brand/Primary
                  borderRadius: BorderRadius.circular(1000.r),
                ),
                child: AppText(
                  'Continue',
                  style: AppStyle.textBold16.copyWith(
                    color: Colors.white, // Text/White
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Bottom space for home indicator
            SizedBox(height: 34.h),
          ],
        ),
      ),
    );
  }
}
