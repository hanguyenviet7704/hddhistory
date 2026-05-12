part of '../../../onboard_v2.dart';

class OnboardV2NotificationPreview extends StatelessWidget {
  const OnboardV2NotificationPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 375.w,
          height: 306.w,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    key: const Key('onboard_v2_notification_phone_preview'),
                    AppAsset.images.app.mobileNoti.path,
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: 37.08.w,
                  top: 195.23.w,
                  child: const OnboardV2FloatingNotificationCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
