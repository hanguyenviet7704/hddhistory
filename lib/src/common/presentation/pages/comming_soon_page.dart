part of '../../common.dart';

class CommingSoonPage extends StatelessWidget {
  const CommingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAsset.images.common.commingSoonBg.path),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                40.verticalSpace,
                AppText(
                  context.text.common.fakedoorComingSoon,
                  style: AppStyle.text40.copyWith(color: AppColorLight.surface),
                  textAlign: TextAlign.center,
                ),
                20.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppText(
                    context.text.common.fakedoorFeaturesNameIsAlmostReady(featuresName: 'Art Story'),
                    style: AppStyle.text24.copyWith(color: AppColorLight.surface),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
                40.verticalSpace,
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? null : double.infinity,
                      child: AppButton.secondary(
                        onPressed: () => context.back(),
                        child: AppText(
                          context.text.common.fakedoorIDoNotWantNotifications,
                          style: AppStyle.textBold20.copyWith(color: const Color(0xFF7F8EA4)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? null : double.infinity,
                      child: AppButton.primary(
                        onPressed: () => context.back(),
                        child: AppText(
                          context.text.common.fakedoorNotifyMe,
                          style: AppStyle.textBold20.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                40.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
