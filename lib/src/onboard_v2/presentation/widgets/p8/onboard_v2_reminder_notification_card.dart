part of '../../../onboard_v2.dart';

/// Thẻ thông báo giả nổi trên khung điện thoại ở S8.
///
/// Khác thẻ của màn xin quyền cũ ([OnboardV2FloatingNotificationCard], vẫn còn
/// dùng ở `notification_request_page`): design mới cho thẻ viền mảnh hơn, ô
/// biểu tượng to hơn, chữ phụ nhỏ hơn, và chuyển động là "rơi xuống rồi thu
/// lên" lặp lại (`v2notif`) chứ không phải trôi bồng bềnh.
class OnboardV2ReminderNotificationCard extends StatefulWidget {
  const OnboardV2ReminderNotificationCard({super.key});

  @override
  State<OnboardV2ReminderNotificationCard> createState() => _OnboardV2ReminderNotificationCardState();
}

class _OnboardV2ReminderNotificationCardState extends State<OnboardV2ReminderNotificationCard> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 4200);
  static const _curve = Cubic(0.2, 0.8, 0.25, 1);

  /// Mốc của `v2notif`: rơi từ trên xuống (0→10%), nảy về đúng chỗ (10→16%),
  /// đứng yên tới 82%, thu lên và mờ đi (82→92%), nghỉ tới hết chu kỳ.
  static const _dropEnd = 0.10;
  static const _settleEnd = 0.16;
  static const _holdEnd = 0.82;
  static const _exitEnd = 0.92;
  static const _hiddenShift = -0.38;
  static const _overshoot = 0.04;

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sync(context.read<OnboardV2Cubit>().state.currentPage == OnboardV2PageStep.p8Reminder);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// Gọi từ post-frame hoặc listener. Không được gọi trong `build` — đặt lại
  /// `_controller.value` báo listener ngay, tức là đánh dấu rebuild trong lúc
  /// đang build.
  void _sync(bool isCurrentPage) {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = _settleEnd;
      return;
    }
    if (isCurrentPage) {
      if (_controller.isAnimating) return;
      _controller.value = 0;
      unawaited(_controller.repeat());
    } else if (_controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    return BlocListener<OnboardV2Cubit, OnboardV2State>(
      listenWhen: (previous, current) => previous.currentPage != current.currentPage,
      listener: (_, state) => _sync(state.currentPage == OnboardV2PageStep.p8Reminder),
      child: _reduceMotion
          ? card
          : AnimatedBuilder(
              animation: _controller,
              child: card,
              builder: (context, child) {
                final frame = _resolve(_controller.value);
                return Opacity(
                  opacity: frame.opacity,
                  child: FractionalTranslation(translation: Offset(0, frame.shift), child: child),
                );
              },
            ),
    );
  }

  _NotifFrame _resolve(double t) {
    if (t < _dropEnd) {
      final eased = _curve.transform(t / _dropEnd);
      return _NotifFrame(opacity: eased, shift: ui.lerpDouble(_hiddenShift, _overshoot, eased)!);
    }
    if (t < _settleEnd) {
      final eased = _curve.transform((t - _dropEnd) / (_settleEnd - _dropEnd));
      return _NotifFrame(opacity: 1, shift: ui.lerpDouble(_overshoot, 0, eased)!);
    }
    if (t < _holdEnd) return const _NotifFrame(opacity: 1, shift: 0);
    if (t < _exitEnd) {
      final eased = _curve.transform((t - _holdEnd) / (_exitEnd - _holdEnd));
      return _NotifFrame(opacity: 1 - eased, shift: _hiddenShift * eased);
    }
    return const _NotifFrame(opacity: 0, shift: _hiddenShift);
  }

  Widget _buildCard(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = context.select<OnboardV2Cubit, OnboardEntity>((cubit) => cubit.state.onboardData);
    final title = '${onbCopy(onboardData, 'onboardingV2NotificationCardTitle', fallback: onboardingL10n.onboardingV2NotificationCardTitle)} \u{1F31F}';
    return Container(
      key: const Key('onboard_v2_reminder_notification_card'),
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment(-0.91, -0.42),
          end: Alignment(0.91, 0.42),
          colors: [Color(0xFF8A82EC), Color(0xFFCDA2E4), Color(0xFFF4B27A)],
          stops: [0, 0.48, 1],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF252525).op(0.16), blurRadius: 30.r, offset: Offset(0, 12.h)),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(color: AppCustomColor.backgroundWhite, borderRadius: BorderRadius.circular(15.r)),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -0.87),
                  end: Alignment(0.5, 0.87),
                  colors: [Color(0xFF7C79EC), Color(0xFF5045C9)],
                ),
              ),
              alignment: Alignment.center,
              // Dấu hiệu thương hiệu "?" (glyph Poppins-Bold), CÙNG một đường
              // vector với biểu tượng nhỏ của thông báo Android và Live Activity
              // trên iOS — xem `drawable/ic_stat_meup.xml`. Trước đây chỗ này vẽ
              // nhầm ký hiệu vô cực.
              child: SvgPicture.asset(AppAsset.svg.app.obBrandMark, width: 36.w, height: 36.w),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.text14.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary, height: 1.3),
                        ),
                      ),
                      8.horizontalSpace,
                      AppText(
                        onbCopy(onboardData, 'onboardingV2NotificationCardTimestamp', fallback: onboardingL10n.onboardingV2NotificationCardTimestamp),
                        maxLines: 1,
                        style: AppStyle.text12.copyWith(color: AppCustomColor.onboardMutedLabel, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ],
                  ),
                  1.verticalSpace,
                  AppText(
                    onbCopy(onboardData, 'onboardingV2NotificationCardBody', fallback: onboardingL10n.onboardingV2NotificationCardBody),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.text12.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w500, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifFrame {
  const _NotifFrame({required this.opacity, required this.shift});

  final double opacity;

  /// Theo TỈ LỆ chiều cao thẻ, đúng như `translateY(%)` của design.
  final double shift;
}
