part of '../../../onboard_v2.dart';

class OnboardV2FloatingNotificationCard extends StatefulWidget {
  const OnboardV2FloatingNotificationCard({super.key});

  @override
  State<OnboardV2FloatingNotificationCard> createState() => _OnboardV2FloatingNotificationCardState();
}

class _OnboardV2FloatingNotificationCardState extends State<OnboardV2FloatingNotificationCard> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _entryDuration = Duration(milliseconds: 640);
  static const _floatDuration = Duration(milliseconds: 3200);

  late final AnimationController _entryController;
  late final AnimationController _floatController;
  late final Animation<double> _entryOffset;
  late final Listenable _motionListenable;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryController = AnimationController(vsync: this, duration: _entryDuration)..addStatusListener(_handleEntryStatus);
    _floatController = AnimationController(vsync: this, duration: _floatDuration);
    _motionListenable = Listenable.merge([_entryController, _floatController]);
    _entryOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -28, end: 2).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 82,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 2, end: 0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
    ]).animate(_entryController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion == _reduceMotion && (_reduceMotion || _entryController.isAnimating || _floatController.isAnimating)) return;
    _reduceMotion = reduceMotion;
    _syncMotionState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_reduceMotion) return;

    if (state == AppLifecycleState.resumed) {
      _syncMotionState();
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _entryController.stop(canceled: false);
      _floatController.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryController
      ..removeStatusListener(_handleEntryStatus)
      ..dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      key: const Key('onboard_v2_notification_card_motion'),
      animation: _motionListenable,
      builder: (context, child) {
        final motion = _resolveMotion();
        return Transform.translate(
          key: const Key('onboard_v2_notification_card_transform'),
          offset: Offset(0, motion.offsetY),
          child: _buildCard(context, motion.shadow),
        );
      },
    );
  }

  void _handleEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _startFloat();
    }
  }

  void _syncMotionState() {
    if (_reduceMotion) {
      _entryController.value = 1;
      _floatController
        ..stop()
        ..value = 0;
      return;
    }

    if (!_entryController.isCompleted) {
      unawaited(_entryController.forward());
      return;
    }

    _startFloat();
  }

  void _startFloat() {
    if (!mounted || _reduceMotion || _floatController.isAnimating) return;
    unawaited(_floatController.repeat());
  }

  _NotificationCardMotion _resolveMotion() {
    if (_reduceMotion) {
      return _NotificationCardMotion(
        offsetY: 0,
        shadow: BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 8.r, offset: Offset(0, 2.w)),
      );
    }

    final entryY = _entryOffset.value.w;
    if (!_entryController.isCompleted) {
      return _NotificationCardMotion(
        offsetY: entryY,
        shadow: BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 8.r, offset: Offset(0, 2.w)),
      );
    }

    final floatWave = math.sin(_floatController.value * math.pi * 2);
    final liftProgress = ((floatWave + 1) / 2).clamp(0.0, 1.0);
    final lowShadow = BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 8.r, offset: Offset(0, 2.w));
    final highShadow = BoxShadow(color: AppCustomColor.brandPrimary.op(0.24), blurRadius: 18.r, offset: Offset(0, 8.w));
    return _NotificationCardMotion(
      offsetY: -floatWave * 6.w,
      shadow: BoxShadow.lerp(lowShadow, highShadow, liftProgress) ?? lowShadow,
    );
  }

  Widget _buildCard(BuildContext context, BoxShadow shadow) {
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = context.select<OnboardV2Cubit, OnboardEntity>((cubit) => cubit.state.onboardData);
    final title = '${onbCopy(onboardData, 'onboardingV2NotificationCardTitle', fallback: onboardingL10n.onboardingV2NotificationCardTitle)} \u{1F31F}';
    return Container(
      key: const Key('onboard_v2_notification_card'),
      width: 300.w,
      height: 74.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: GradientBoxBorder(gradient: OnboardV2GradientText.gradient, width: 2.w),
        boxShadow: [shadow],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        child: Row(
          children: [
            _buildLogoTile(),
            16.horizontalSpace,
            Expanded(
              child: _buildTextBlock(
                title: title,
                timestamp: onbCopy(onboardData, 'onboardingV2NotificationCardTimestamp', fallback: onboardingL10n.onboardingV2NotificationCardTimestamp),
                body: onbCopy(onboardData, 'onboardingV2NotificationCardBody', fallback: onboardingL10n.onboardingV2NotificationCardBody),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoTile() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(color: AppCustomColor.brandPrimary, borderRadius: BorderRadius.circular(8.r)),
      child: Icon(Icons.all_inclusive_rounded, color: AppCustomColor.textWhite, size: 26.w),
    );
  }

  Widget _buildTextBlock({
    required String title,
    required String timestamp,
    required String body,
  }) {
    return SizedBox(
      height: 50.w,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 40.w,
            height: 25.w,
            child: AppText(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary, height: 1.45),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: 32.w,
            height: 21.w,
            child: AppText(
              timestamp,
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted, height: 1.45),
            ),
          ),
          Positioned(
            left: 0,
            top: 25.w,
            right: 0,
            height: 25.w,
            child: AppText(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCardMotion {
  const _NotificationCardMotion({
    required this.offsetY,
    required this.shadow,
  });

  final double offsetY;
  final BoxShadow shadow;
}
