part of '../../auth.dart';

class AuthIntro extends StatelessWidget {
  const AuthIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: SizedBox(
        height: 1.sh,
        child: Container(
          padding: EdgeInsets.all(48.w),
          color: AppColorLight.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  context.back();
                  AppService.instance.appTrackingService.trackEvent(TrackingKey.signinExit);
                },
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, color: AppCustomColor.grey27, size: 24.w),
                    AppText(
                      context.text.authBack,
                      style: AppStyle.textBold20.copyWith(color: AppCustomColor.grey27),
                    ),
                  ],
                ),
              ),
              AppText(
                context.text.authStartLearningWithCreativity,
                style: AppStyle.text40.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF364152),
                ),
                maxLines: 10,
              ),
             
            ],
          ),
        ),
      ),
    );
  }
}
