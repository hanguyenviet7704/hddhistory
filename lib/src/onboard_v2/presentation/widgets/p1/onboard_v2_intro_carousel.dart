part of '../../../onboard_v2.dart';

class OnboardV2IntroCarousel extends StatefulWidget {
  const OnboardV2IntroCarousel({
    super.key,
    this.isVisible = true,
  });

  final bool isVisible;

  @override
  State<OnboardV2IntroCarousel> createState() => _OnboardV2IntroCarouselState();
}

class _OnboardV2IntroCarouselState extends State<OnboardV2IntroCarousel> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _cycleInterval = Duration(milliseconds: 3000);
  static const _slotDuration = Duration(milliseconds: 700);
  static const _slotCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  static final _cards = [
    AppAsset.images.app.onboardExploreDeco.path,
    AppAsset.images.app.onboardConnectDecor.path,
    AppAsset.images.app.onboardFeelDecor.path,
    AppAsset.images.app.onboardLearnDecor.path,
    AppAsset.images.app.onboardThinkDecor.path,
    AppAsset.images.app.onboardWorkDecor.path,
  ];

  late final AnimationController _slotController;
  Timer? _cycleTimer;
  int _leftCardIndex = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _slotController = AnimationController(vsync: this, duration: _slotDuration)..addStatusListener(_handleSlotStatus);
  }

  @override
  void didUpdateWidget(covariant OnboardV2IntroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible == widget.isVisible) return;
    _syncMotionState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion == _reduceMotion && (_reduceMotion || _cycleTimer != null || !widget.isVisible)) return;
    _reduceMotion = reduceMotion;
    _syncMotionState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_canAnimate) return;

    if (state == AppLifecycleState.resumed) {
      _syncMotionState();
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _cycleTimer?.cancel();
      _cycleTimer = null;
      _slotController.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cycleTimer?.cancel();
    _slotController
      ..removeStatusListener(_handleSlotStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('onboard_v2_intro_carousel'),
      width: 335.w,
      height: 190.h,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          key: const Key('onboard_v2_intro_carousel_animation'),
          animation: _slotController,
          builder: (context, child) {
            final progress = _reduceMotion ? 0.0 : _slotCurve.transform(_slotController.value);
            final renderedCards = List.generate(5, (index) {
              final startPosition = index - 1;
              final asset = _cards[_wrapCardIndex(_leftCardIndex + startPosition)];
              final values = _OnboardV2CarouselSlotValues.lerp(
                _slotFor(startPosition),
                _slotFor(startPosition - 1),
                progress,
              );
              return _OnboardV2CarouselCard(asset: asset, values: values);
            })..sort((a, b) => a.values.z.compareTo(b.values.z));

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: renderedCards,
            );
          },
        ),
      ),
    );
  }

  void _startCycleTimer() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(_cycleInterval, (_) => _advanceSlot());
  }

  void _advanceSlot() {
    if (!mounted || !_canAnimate || _slotController.isAnimating) return;
    unawaited(_slotController.forward(from: 0));
  }

  void _handleSlotStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _leftCardIndex = _wrapCardIndex(_leftCardIndex + 1);
      _slotController.value = 0;
    });
  }

  void _stopMotion({required bool resetSlot}) {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    _slotController.stop(canceled: false);
    if (resetSlot && _slotController.value != 0) {
      _slotController.value = 0;
    }
  }

  void _syncMotionState() {
    if (!_canAnimate) {
      _stopMotion(resetSlot: _reduceMotion);
      return;
    }
    if (_slotController.value > 0 && _slotController.value < 1 && !_slotController.isAnimating) {
      unawaited(_slotController.forward());
    }
    _startCycleTimer();
  }

  bool get _canAnimate => !_reduceMotion && widget.isVisible;

  int _wrapCardIndex(int index) => index % _cards.length < 0 ? index % _cards.length + _cards.length : index % _cards.length;

  _OnboardV2CarouselSlotValues _slotFor(int position) {
    if (position <= -1) return _OnboardV2CarouselSlotValues.farLeft;
    if (position == 0) return _OnboardV2CarouselSlotValues.left;
    if (position == 1) return _OnboardV2CarouselSlotValues.center;
    if (position == 2) return _OnboardV2CarouselSlotValues.right;
    return _OnboardV2CarouselSlotValues.farRight;
  }
}
