part of '../../lesson.dart';

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
                      AppAsset.images.app.reverseLeft.path,
                      width: 70.w,
                    ),
                    24.verticalSpace,

                    // Title and subtitle
                    AppText(
                      context.text.reviewTimeTitle,
                      style: AppStyle.textBold24.copyWith(
                        color: const Color(0xFF1A202C),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    4.verticalSpace,
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
