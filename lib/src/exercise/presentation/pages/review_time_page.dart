part of '../../exercise.dart';

class ReviewTimePage extends StatelessWidget {
  const ReviewTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewTimeView();
  }
}

class ReviewTimeView extends StatelessWidget {
  const ReviewTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content - centered vertically
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 36.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Image.asset(
                      'assets/images/app/reverse_left.png',
                      width: 70.w,
                      height: 70.h,
                    ),
                    SizedBox(height: 24.h),

                    // Title and subtitle
                    Column(
                      children: [
                        AppText(
                          context.text.reviewTimeTitle,
                          style: AppStyle.textBold24.copyWith(
                            color: const Color(0xFF1A202C),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          context.text.reviewTimeSubtitle,
                          style: AppStyle.text14.copyWith(
                            color: const Color(0xFF7F8EA4),
                            height: 1.75,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to review exercise
                },
                child: Container(
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.blue55,
                    borderRadius: BorderRadius.circular(1000.r),
                  ),
                  child: Center(
                    child: AppText(
                      context.text.exerciseSkipButton,
                      style: AppStyle.textBold16.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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
