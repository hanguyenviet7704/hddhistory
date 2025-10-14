part of '../intro.dart';

class SplashContentCard extends StatelessWidget {
  const SplashContentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.only(bottom: 25.h),
      padding: EdgeInsets.only(top: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppCustomColor.yellowFDF0,
            AppCustomColor.yellowFDE1,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(AppAsset.images.splashIntro.path, width: 58.w),
                16.horizontalSpace,
                AppText(context.text.loadingSplashReadyToUnleashInfiniteCreativity, style: AppStyle.textBold20),
              ],
            ),
          ),
          20.verticalSpace,
          SizedBox(
            width: 0.6.sw,
            child: Container(
              height: 12.h,
              decoration: BoxDecoration(
                color: AppColorLight.surface,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Container(
                width: double.infinity,
                height: 12.h,
                decoration: BoxDecoration(
                  color: AppCustomColor.blue23,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ).animate().scaleX(
                begin: 0.0,
                end: 1.0,
                duration: 3000.ms,
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
