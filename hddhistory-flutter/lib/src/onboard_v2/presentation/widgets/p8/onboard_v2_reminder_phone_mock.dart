part of '../../../onboard_v2.dart';

/// Khung điện thoại giả của S8: bánh xe chọn giờ nằm TRONG máy, phần dưới mờ
/// dần về trắng, và thẻ thông báo nổi đè lên mép dưới.
///
/// Thân máy cao hơn vùng nhìn thấy (368 so với 286) nên đáy máy bị cắt — đúng
/// như design, máy như đang trồi lên từ dưới màn hình. Thẻ thông báo nằm NGOÀI
/// vùng cắt để tràn ra hai bên thân máy.
class OnboardV2ReminderPhoneMock extends StatelessWidget {
  const OnboardV2ReminderPhoneMock({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _mockWidth = 300.0;
  static const _mockHeight = 286.0;
  static const _bodyWidth = 272.0;
  static const _bodyHeight = 368.0;
  static const _bezel = 14.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _mockWidth.w,
      height: _mockHeight.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRect(
            child: SizedBox(
              width: _bodyWidth.w,
              height: _mockHeight.h,
              child: Stack(
                children: [
                  Container(
                    width: _bodyWidth.w,
                    height: _bodyHeight.h,
                    padding: EdgeInsets.all(_bezel.w),
                    decoration: BoxDecoration(
                      color: AppCustomColor.onboardPhoneFrame,
                      borderRadius: BorderRadius.circular(58.r),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundWhite,
                        borderRadius: BorderRadius.circular(44.r),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _bezel.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 92.w,
                        height: 26.h,
                        decoration: BoxDecoration(
                          color: AppCustomColor.onboardPhoneFrame,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50.h,
                    left: _bezel.w,
                    right: _bezel.w,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: OnboardV2TimeWheel(value: value, onChanged: onChanged),
                    ),
                  ),
                  // Mép dưới chìm dần về trắng. Phải cho con trỏ đi xuyên qua,
                  // nếu không nửa dưới bánh xe không kéo được.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 112.h,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppCustomColor.backgroundWhite.op(0),
                              AppCustomColor.backgroundWhite,
                            ],
                            stops: const [0, 0.66],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 26.h,
            left: 0,
            right: 0,
            child: const OnboardV2ReminderNotificationCard(),
          ),
        ],
      ),
    );
  }
}
