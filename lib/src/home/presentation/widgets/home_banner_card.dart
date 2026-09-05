part of '../../home.dart';

/// Admin-configurable promo carousel (design `2 · Home`): a full-width image
/// slot between "New today" and "Jump back in". Content comes from
/// GET /home-banner — when the config is off, has no image yet, or the fetch
/// failed, the whole section INCLUDING its bottom spacing collapses to zero
/// height, so Home reads exactly as it did before the slot existed.
///
/// The server hands over only the slides this reader should see, already in
/// order, so this widget holds no targeting logic — one dot per slide received.
/// With exactly one slide there are no dots and no timer, which is byte-for-byte
/// the single-banner behaviour this replaced.
class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) => previous.homeBanner != current.homeBanner,
      builder: (context, state) {
        final banner = state.homeBanner;
        if (banner == null || !banner.isVisible) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 22.h),
          child: _HomeBannerCarousel(slides: banner.effectiveSlides),
        );
      },
    );
  }
}

/// The carousel itself, split out because it needs a [State] for the page
/// controller and the auto-advance timer — [HomeBannerCard] stays a pure
/// stateless read of the cubit.
class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({required this.slides});

  final List<HomeBannerSlideEntity> slides;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  /// 2.5s per slide (user call, 2026-08-12): a promo image is read at a glance,
  /// and Home is a screen people pass through — at 5s a reader who scrolls by
  /// only ever saw the first slide.
  ///
  /// Measured from the END of the previous animation, not its start: the timer is
  /// restarted in [_advance]'s completion rather than being periodic, so every
  /// slide gets the full dwell instead of 2.5s minus the 450ms it spent moving.
  static const Duration _autoAdvanceInterval = Duration(milliseconds: 2500);
  static const Duration _autoAdvanceAnimation = Duration(milliseconds: 450);

  final PageController _pageController = PageController();
  Timer? _autoAdvanceTimer;
  int _currentIndex = 0;
  bool _isStoppedByReader = false;

  bool get _isCarousel => widget.slides.length > 1;

  @override
  void initState() {
    super.initState();
    _restartAutoAdvance();
    // The initial slide is visible the moment this carousel first paints —
    // report it exactly like every later page change does.
    if (widget.slides.isNotEmpty) {
      AppDI.injector.get<HomeCubit>().trackBannerImpression(widget.slides.first.campaignKey);
    }
  }

  @override
  void didUpdateWidget(_HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The config can change under us (a campaign switched on while Home is
    // open): a shorter list would leave the timer driving past the end.
    if (oldWidget.slides.length == widget.slides.length) return;
    _currentIndex = _currentIndex.clamp(0, widget.slides.length - 1);
    _restartAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!_isCarousel || _isStoppedByReader) return;
    _autoAdvanceTimer = Timer(_autoAdvanceInterval, _advance);
  }

  /// Stops the carousel moving on its own for the rest of this Home visit.
  ///
  /// Once the reader has taken hold of it, an automatic slide is the widget
  /// yanking the page out from under their thumb — and having touched it, they
  /// already know it can be swiped, which is the only thing auto-advance was
  /// there to tell them.
  ///
  /// A latch, not just a cancelled timer: the touch can land WHILE a slide is
  /// animating, and that animation's completion is what schedules the next one.
  void _stopAutoAdvance() {
    _isStoppedByReader = true;
    _autoAdvanceTimer?.cancel();
  }

  Future<void> _advance() async {
    if (!mounted || !_pageController.hasClients) return;
    final next = (_currentIndex + 1) % widget.slides.length;
    await _pageController.animateToPage(
      next,
      duration: _autoAdvanceAnimation,
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    _restartAutoAdvance();
  }

  void _openSlide(HomeBannerSlideEntity slide) {
    if (slide.linkUrl.isEmpty) return;
    AppHaptic.select();
    AppDI.injector.get<HomeCubit>().trackBannerClick(slide.campaignKey);
    unawaited(openConfiguredLink(slide.linkUrl));
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 78.h,
          child: Listener(
            // A raw pointer-down, not the PageView's own scroll callbacks: the
            // reader may press a slide to tap its link without ever scrolling,
            // and that is still them taking hold of the carousel.
            onPointerDown: (_) => _stopAutoAdvance(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              physics: _isCarousel ? null : const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                AppDI.injector.get<HomeCubit>().trackBannerImpression(slides[index].campaignKey);
              },
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Semantics(
                  button: slide.linkUrl.isNotEmpty,
                  image: true,
                  label: context.l10n.home.homeBannerSemantic,
                  child: GestureDetector(
                    onTap: () => _openSlide(slide),
                    child: CacheNetworkGraphic(
                      url: slide.imageUrl,
                      borderRadius: BorderRadius.circular(18.r),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_isCarousel) ...[
          SizedBox(height: 10.h),
          _HomeBannerDots(count: slides.length, activeIndex: _currentIndex),
        ],
      ],
    );
  }
}

/// Page indicator: the active slide is a stadium, the rest are circles. Excluded
/// from semantics — it is a picture of state the reader already has, and reading
/// out "dot, dot, dot" after the banner label adds nothing.
class _HomeBannerDots extends StatelessWidget {
  const _HomeBannerDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: index == activeIndex ? 16.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                // Match the Jump-back-in carousel dots: brand purple, not the
                // Material scheme's coral primary.
                color: index == activeIndex
                    ? AppCustomColor.brandPrimary
                    : AppCustomColor.brandPrimary.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
        ],
      ),
    );
  }
}
