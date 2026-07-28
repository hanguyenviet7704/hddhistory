part of '../../../lesson.dart';

/// The unified keypoint reading screen's body: a vertically-swipeable
/// `PageView` of cards (theory content / quiz questions / a terminal "done"
/// card), driven by [KeypointCardCubit]. Replaces the old
/// `TabController`/`TabBarView` Read-vs-Listen split.
///
/// Forward swipe/tap past the live edge is structurally impossible — the
/// `PageView` is built with `itemCount: furthestCardIndex + 1` — so this
/// widget never has to re-check the progress gate itself.
class KeypointCardShell extends StatefulWidget {
  const KeypointCardShell({
    super.key,
    required this.bodyFactory,
    required this.onAnswerChecked,
  });

  final LessonBodyFactory bodyFactory;
  final ValueChanged<bool> onAnswerChecked;

  @override
  State<KeypointCardShell> createState() => _KeypointCardShellState();
}

/// What a vertical drag on the card area was claimed for — see
/// [_KeypointCardShellState._dragMode].
enum _DragMode { content, page, lift }

class _KeypointCardShellState extends State<KeypointCardShell> {
  late final PageController _pageController;

  /// Raw finger travel for the current gesture, in logical pixels (negative =
  /// dragging up / forward).
  double _dragDy = 0;
  bool _isDragging = false;

  /// What the current gesture was claimed for, decided once it passes
  /// [_dragSlop]: `null` = undecided, `_DragMode.content` = the card's own
  /// text scroller owns it (we keep out of the way), `_DragMode.page` = drag
  /// the card stack itself, `_DragMode.lift` = there is no next page to drag
  /// into yet (the live card advances on release), so give elastic feedback.
  _DragMode? _dragMode;
  double _pageStartPixels = 0;
  double _liftOffset = 0;

  static const _dragSlop = 8.0;

  /// Design's own card-swipe threshold (its pointer handlers commit at 70px).
  static const _swipeThreshold = 70.0;

  /// Vertical padding a card page adds around its card (see [_KeypointCardPage]
  /// bodies) — subtracted from the viewport so a full-height card doesn't
  /// overflow into a scroll.
  static const _cardVerticalInset = 40.0;

  /// Whether the CURRENT card's own content scroller is at its top / bottom
  /// edge. Both default to true: a card whose content fits never emits a scroll
  /// notification at all, and that case must still be swipeable.
  bool _contentAtTop = true;
  bool _contentAtBottom = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: context.read<KeypointCardCubit>().state.viewedCardIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KeypointCardCubit, KeypointCardState>(
      listenWhen: (previous, current) => previous.viewedCardIndex != current.viewedCardIndex,
      listener: (context, state) => _followViewedCardIndex(state),
      builder: (context, state) {
        if (state.cards.isEmpty) return const SizedBox.shrink();

        final liveDescriptor = state.cards[state.furthestCardIndex];
        final isViewingLive = state.viewedCardIndex == state.furthestCardIndex;
        // Theory cards advance by swiping up (design) — no Continue button.
        // Quiz cards keep their bottom action, since checking an answer is a
        // deliberate commit the design also renders as a button.
        final showBottomAction = isViewingLive && liveDescriptor.isQuiz;

        return Stack(
          children: [
            // The bottom action is an OVERLAY, never a Column sibling of the
            // PageView. As a sibling it shrank the PageView's viewport the
            // moment a quiz card went live, and the controller's pixel offset
            // (pageIndex × old viewport height) then resolved to a much later
            // page in the new metrics — the view visibly shot upwards on the
            // theory→quiz hand-off. An overlay keeps the viewport constant.
            Column(
              children: [
                Expanded(
                  // Card paging is driven by RAW POINTER events, not by the
                  // PageView's own physics (hence NeverScrollableScrollPhysics
                  // below). Each card's body is its own vertical scroller, and
                  // Flutter hands a vertical drag to the innermost scrollable
                  // for the whole gesture — it never re-offers it to an outer
                  // vertical PageView, so physics-driven paging simply cannot
                  // fire while reading. A `Listener` sees pointer moves without
                  // entering the gesture arena, so text scrolling and card
                  // swiping coexist (this is what the design prototype does
                  // with its own onPointerDown/Move/Up handlers).
                  // ScrollMetricsNotification fires when a scroller LAYS OUT,
                  // before any drag — that's what tells us a short card has
                  // nothing to scroll (so a swipe should move on immediately)
                  // versus a long one the user still has to read through.
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (notification) {
                      _applyContentMetrics(notification.metrics, notification.depth);
                      return false;
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        _applyContentMetrics(notification.metrics, notification.depth);
                        return false;
                      },
                      child: Listener(
                        onPointerDown: (_) {
                          _dragDy = 0;
                          _dragMode = null;
                          _isDragging = true;
                        },
                        onPointerMove: (event) => _handleDragUpdate(event.delta.dy, state, liveDescriptor),
                        onPointerCancel: (_) => _settleDrag(context, state, liveDescriptor, cancelled: true),
                        onPointerUp: (_) => _settleDrag(context, state, liveDescriptor),
                        // Translated during a `lift` drag so the last card
                        // still tracks the finger even though there is no page
                        // beyond it yet — without this the gesture felt dead
                        // until release.
                        child: Transform.translate(
                          offset: Offset(0, _liftOffset),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Cards are full-height panels (design), not boxes
                              // that shrink to their text. `LessonContentCard`
                              // already honours this scope — the deleted Read
                              // surface used to be the one providing it, which is
                              // why cards had started collapsing to their content.
                              return LessonCardMinHeightScope(
                                minHeight: math.max(0, constraints.maxHeight - _cardVerticalInset),
                                child: PageView.builder(
                                  key: const ValueKey('keypoint-card-page-view'),
                                  controller: _pageController,
                                  scrollDirection: Axis.vertical,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.furthestCardIndex + 1,
                                  onPageChanged: (index) => context.read<KeypointCardCubit>().viewCard(index),
                                  itemBuilder: (context, index) => _KeypointCardPage(
                                    cardIndex: index,
                                    descriptor: state.cards[index],
                                    isLive: index == state.furthestCardIndex,
                                    bodyFactory: widget.bodyFactory,
                                    onAnswerChecked: widget.onAnswerChecked,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (showBottomAction)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LessonStickyBottomAction(child: _liveBottomButton(context, liveDescriptor)),
              ),
            // Design shows the swipe affordance only on the first couple of
            // cards — once the gesture is learned the pill stops nagging.
            if (isViewingLive && liveDescriptor.isTheory && state.viewedCardIndex < 2)
              _SwipeHintPill(isLastCard: state.furthestCardIndex == state.cards.length - 1),
          ],
        );
      },
    );
  }

  /// Remembers whether the card body's own scroller is parked at an edge, so a
  /// swipe only changes card once the user has actually read to the end (or the
  /// content was short enough that there was nothing to scroll).
  ///
  /// [depth] filters out the `PageView`'s own metrics (depth 0): its extents
  /// describe card paging, not the text the user is reading — only the card
  /// body's nested scroller (depth ≥ 1) answers "have they reached the end?".
  void _applyContentMetrics(ScrollMetrics metrics, int depth) {
    if (depth == 0) return;
    if (metrics.axis != Axis.vertical) return;
    _contentAtTop = metrics.extentBefore <= 1;
    _contentAtBottom = metrics.extentAfter <= 1;
  }

  /// Claims the gesture on the first meaningful movement, then drags the card
  /// stack with the finger for the rest of it.
  void _handleDragUpdate(double delta, KeypointCardState state, KeypointCardDescriptor liveDescriptor) {
    if (!_isDragging) return;
    _dragDy += delta;

    if (_dragMode == null) {
      if (_dragDy.abs() < _dragSlop) return;
      _dragMode = _resolveDragMode(state, liveDescriptor);
      if (_dragMode == _DragMode.page && _pageController.hasClients) {
        _pageStartPixels = _pageController.position.pixels;
      }
    }

    switch (_dragMode!) {
      // The card's own text scroller already moved the content; nothing to do.
      case _DragMode.content:
        return;
      case _DragMode.page:
        if (!_pageController.hasClients) return;
        final position = _pageController.position;
        _pageController.jumpTo((_pageStartPixels - _dragDy).clamp(position.minScrollExtent, position.maxScrollExtent));
      case _DragMode.lift:
        // Elastic: follows the finger at a fraction so it reads as resistance
        // rather than a free page turn into nothing.
        setState(() => _liftOffset = (_dragDy * 0.35).clamp(-90.0, 90.0));
    }
  }

  _DragMode _resolveDragMode(KeypointCardState state, KeypointCardDescriptor liveDescriptor) {
    final isForward = _dragDy < 0;
    if (isForward) {
      if (!_contentAtBottom) return _DragMode.content;
      // A revealed card ahead means a real page to drag into.
      if (state.viewedCardIndex < state.furthestCardIndex) return _DragMode.page;
      // At the live edge, only a theory card can be turned by swiping. A quiz
      // commits through its Check action, so a drag there must not move the
      // stack at all — the elastic feedback made the card visibly ride up
      // behind a gesture that could never complete.
      return liveDescriptor.isTheory ? _DragMode.lift : _DragMode.content;
    }
    if (!_contentAtTop) return _DragMode.content;
    // Nothing behind the first card, so no rubber-band there either.
    return state.viewedCardIndex > 0 ? _DragMode.page : _DragMode.content;
  }

  void _settleDrag(
    BuildContext context,
    KeypointCardState state,
    KeypointCardDescriptor liveDescriptor, {
    bool cancelled = false,
  }) {
    if (!_isDragging) return;
    _isDragging = false;
    final dy = _dragDy;
    final mode = _dragMode;
    _dragDy = 0;
    _dragMode = null;
    if (_liftOffset != 0) setState(() => _liftOffset = 0);
    if (cancelled || mode == null || mode == _DragMode.content) return;

    final committed = dy.abs() >= _swipeThreshold;

    if (mode == _DragMode.page) {
      // Snap: to the neighbour if the drag committed, back to where it started
      // otherwise. `onPageChanged` reports the landing card, which is what
      // moves narration (see `KeypointCardCubit.viewCard`).
      final target = committed ? state.viewedCardIndex + (dy < 0 ? 1 : -1) : state.viewedCardIndex;
      if (committed) AppHaptic.select();
      unawaited(
        _pageController.animateToPage(
          target.clamp(0, state.furthestCardIndex),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }

    // lift: only the forward direction has anywhere to go — advance the live
    // theory card exactly as the old Continue button did. Dragging down on the
    // first card has nothing behind it, so it just springs back (the elastic
    // offset was already reset above).
    if (committed && dy < 0 && liveDescriptor.isTheory) _advanceLiveTheoryCard(context);
  }

  void _advanceLiveTheoryCard(BuildContext context) {
    final theoryCubit = context.read<TheoryCubit>();
    // Same gate the Continue button had: a card requiring an explanation
    // choice stays put until one is made (the hint pill says so).
    if (!theoryCubit.state.canContinue) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointTheoryContinueClick(trackingData);
    }
    AppHaptic.select();
    theoryCubit.nextDocument();
  }

  void _followViewedCardIndex(KeypointCardState state) {
    // Mid-drag the finger owns the controller (see `_handleDragUpdate`); an
    // animation started from here would fight it.
    if (_isDragging) return;
    if (!_pageController.hasClients) return;
    final targetPage = state.viewedCardIndex;
    if (_pageController.page?.round() == targetPage) return;

    final isDoneReveal = state.cards.isNotEmpty && state.cards[targetPage].isDone;
    if (isDoneReveal) {
      // Completion has already fired (or is about to) — no time for an
      // animation before the route transition covers this screen.
      _pageController.jumpToPage(targetPage);
      return;
    }

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _liveBottomButton(BuildContext context, KeypointCardDescriptor descriptor) {
    final cardCubit = context.read<KeypointCardCubit>();
    final Widget activeBody = descriptor.isTheory
        ? TheoryLessonBody(onAnswerChecked: widget.onAnswerChecked)
        : widget.bodyFactory.buildExerciseBody(cardCubit.questionForCard(descriptor));
    return widget.bodyFactory.buildBottomButton(context, activeBody);
  }
}

class _KeypointCardPage extends StatelessWidget {
  const _KeypointCardPage({
    required this.cardIndex,
    required this.descriptor,
    required this.isLive,
    required this.bodyFactory,
    required this.onAnswerChecked,
  });

  final int cardIndex;
  final KeypointCardDescriptor descriptor;
  final bool isLive;
  final LessonBodyFactory bodyFactory;
  final ValueChanged<bool> onAnswerChecked;

  @override
  Widget build(BuildContext context) {
    if (descriptor.isDone) return const KeypointDoneCard();
    if (descriptor.isTheory) {
      return TheoryCardBody(
        cardIndex: cardIndex,
        descriptor: descriptor,
        isLive: isLive,
        onAnswerChecked: onAnswerChecked,
      );
    }
    return QuizCardBody(descriptor: descriptor, isLive: isLive, bodyFactory: bodyFactory);
  }
}

/// Bottom-centered hint that replaces the removed Continue button as the
/// affordance for advancing a theory card — and tells the reader when a card
/// is deliberately holding them (an explanation choice still owed).
class _SwipeHintPill extends StatelessWidget {
  const _SwipeHintPill({required this.isLastCard});

  final bool isLastCard;

  @override
  Widget build(BuildContext context) {
    final canContinue = context.select((TheoryCubit cubit) => cubit.state.canContinue);
    final color = canContinue ? AppCustomColor.brandPrimary : AppCustomColor.errorRed;
    final label = !canContinue
        ? context.l10n.lesson.cardSwipeBlockedHint
        : isLastCard
        ? context.l10n.lesson.cardSwipeReviewHint
        : context.l10n.lesson.cardSwipeHint;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 40.h,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: canContinue
                  ? AppCustomColor.brandPrimary.withValues(alpha: 0.10)
                  : AppCustomColor.errorRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLastCard && canContinue ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 14.sp,
                  color: color,
                ),
                7.horizontalSpace,
                AppText(label, style: AppStyle.textBold12.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Narration on/off control that sits IN the header row, right of the progress
/// pips (design) — a 34×34 translucent circle, not a floating button. Manual
/// seeking happens via swipe/pip-tap (see `KeypointCardCubit`), so unlike the
/// old Listen-mode player this needs no ±10s buttons. Hidden entirely for a
/// keypoint with no usable audio.
class KeypointNarrationToggle extends StatelessWidget {
  const KeypointNarrationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUsableSource = context.select((LessonAudioCubit cubit) => cubit.state.hasUsableSource);
    if (!hasUsableSource) return const SizedBox.shrink();

    final isDarkBg = studyThemeIsDarkBg(context);
    final iconColor = studyThemeOnBg(context, AppCustomColor.brandPrimary);

    return BlocBuilder<LessonAudioCubit, LessonAudioState>(
      builder: (context, audioState) {
        final isPlaying = audioState.isPlaying;
        final isLoading = audioState.isLoading;

        return Semantics(
          button: true,
          label: isPlaying ? context.l10n.lesson.narrationPauseSemantics : context.l10n.lesson.narrationPlaySemantics,
          child: GestureDetector(
            key: const ValueKey('keypoint-card-narration-toggle'),
            behavior: HitTestBehavior.opaque,
            onTap: isLoading ? null : () => _togglePlayback(context, audioState),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: isDarkBg
                    ? const Color(0xFF12141C).withValues(alpha: 0.52)
                    : AppCustomColor.backgroundWhite.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(
                      // Design uses a speaker (on) / muted speaker (off) —
                      // narration is a voice track, not a media player.
                      isPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: isPlaying ? iconColor : iconColor.withValues(alpha: 0.6),
                      size: 18.sp,
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePlayback(BuildContext context, LessonAudioState audioState) async {
    final audioCubit = context.read<LessonAudioCubit>();
    final trackingData = KeypointTrackingData.fromContext();

    if (audioState.isPlaying) {
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointAudioPauseClick(trackingData, audioPosition: audioState.positionSeconds);
      }
      await audioCubit.pause();
      return;
    }

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPlayClick(trackingData);
    }
    await audioCubit.enterAudioMode();
  }
}
