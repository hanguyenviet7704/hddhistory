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
          height: 306.h,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: 59.23.w,
                  top: 15.h,
                  width: 256.55.w,
                  height: 547.h,
                  child: Image.asset(AppAsset.images.app.mobileNoti.path, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 37.5.w,
                  top: 195.23.h,
                  child: const OnboardV2FloatingNotificationCard(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 78.h,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Colors.white],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
