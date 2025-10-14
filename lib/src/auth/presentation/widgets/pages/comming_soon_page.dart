part of '../widgets.dart';

class CommingSoonPage extends StatelessWidget {
  const CommingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAsset.images.common.commingSoonBg.path),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: double.infinity),
            // Image.asset(AppAsset.images.common.commingSoonIntro.path, height: 391.h),
            40.verticalSpace,
            AppText(
              context.text.fakedoorComingSoon,
              style: AppStyle.text40.copyWith(color: AppColorLight.surface),
            ),
            20.verticalSpace,
            AppText(
              context.text.fakedoorFeaturesNameIsAlmostReady(featuresName: 'Art Story'),
              style: AppStyle.text24.copyWith(color: AppColorLight.surface),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            40.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton.secondary(
                  onPressed: () => context.back(),
                  child: context.text.fakedoorIDoNotWantNotifications,
                ),
                24.horizontalSpace,
                AppButton.primary(
                  onPressed: () => context.back(),
                  child: context.text.fakedoorNotifyMe,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
