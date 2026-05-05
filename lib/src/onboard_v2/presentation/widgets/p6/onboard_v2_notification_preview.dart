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
                const _OnboardV2NotificationPhone(),
                Positioned(
                  left: 37.08.w,
                  top: 195.23.w,
                  child: const OnboardV2FloatingNotificationCard(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 78.w,
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

class _OnboardV2NotificationPhone extends StatelessWidget {
  const _OnboardV2NotificationPhone();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 59.22.w,
      top: 15.01.w,
      width: 256.55.w,
      height: 547.31.w,
      child: Container(
        key: const Key('onboard_v2_notification_phone_preview'),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(30.63.r),
          border: Border.all(color: AppCustomColor.borderSecondary, width: 14.w),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -14.w,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 82.42.w,
                  height: 31.43.w,
                  decoration: BoxDecoration(
                    color: AppCustomColor.borderSecondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 49.37.w,
              width: 256.55.w,
              height: 137.47.w,
              child: const _OnboardV2NotificationTimePicker(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardV2NotificationTimePicker extends StatelessWidget {
  const _OnboardV2NotificationTimePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.49.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _OnboardV2TimeColumn(previous: '13', current: '14', next: '15'),
          SizedBox(width: 29.04.w),
          SizedBox(
            width: 11.77.w,
            height: 55.18.w,
            child: Center(
              child: AppText(
                ':',
                style: AppStyle.text36.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.5),
              ),
            ),
          ),
          SizedBox(width: 29.04.w),
          const _OnboardV2TimeColumn(previous: '59', current: '00', next: '01'),
        ],
      ),
    );
  }
}

class _OnboardV2TimeColumn extends StatelessWidget {
  const _OnboardV2TimeColumn({
    required this.previous,
    required this.current,
    required this.next,
  });

  final String previous;
  final String current;
  final String next;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 77.45.w,
      height: 137.47.w,
      child: Column(
        children: [
          _timeText(previous, active: false),
          Expanded(child: _timeText(current, active: true)),
          _timeText(next, active: false),
        ],
      ),
    );
  }

  Widget _timeText(String value, {required bool active}) {
    return SizedBox(
      height: active ? null : 42.6.w,
      child: Center(
        child: Opacity(
          opacity: active ? 1 : 0.35,
          child: AppText(
            value,
            style: (active ? AppStyle.text36 : AppStyle.text20).copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              height: active ? 1.5 : 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
