part of '../../../lesson.dart';

/// The unified keypoint reading screen's body: a vertically-swipeable deck of
/// cards (theory content / quiz questions / a terminal "done" card), driven by
/// [KeypointCardCubit].
///
/// It reads like turning pages in a book: one card holds the screen, the cards
/// either side show a strip of their edge so the deck is legible as a deck, and a
/// swipe commits to the next one. Each card is a FIXED panel — it never slides
/// under the pager's clip; long content scrolls inside it (see
/// [LessonContentCard]), which is what the design does.
///
/// Forward swipe/tap past the live edge is structurally impossible — the
/// `PageView` is built with `itemCount: furthestCardIndex + 1` — so this widget
/// never has to re-check the progress gate itself.
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

  /// Set only when the gate itself failed, to stop it retrying (and re-logging)
  /// on every card change. Whether the paywall is currently up is derived from
  /// [IapCubit.paywallEntryPoint], not tracked here — see
  /// [_maybeOpenInLessonPaywall].
  bool _inLessonPaywallGateBroken = false;

  /// What the current gesture was claimed for, decided once it passes
  /// [_dragSlop]: `null` = undecided, `_DragMode.content` = the card's own
  /// content scroller owns it (we keep out of the way), `_DragMode.page` = drag
  /// the card stack itself, `_DragMode.lift` = there is no next page to drag
  /// into yet (the live card advances on release), so give elastic feedback.
  _DragMode? _dragMode;
  double _pageStartPixels = 0;

  /// Elastic offset for a `lift` drag, as a notifier rather than plain state:
  /// driving it through `setState` rebuilt the whole deck (BlocConsumer +
  /// `PageView.builder`) on every pointer move, which is exactly the gesture the
  /// reader uses most. Only the one `Transform.translate` listens now.
  final ValueNotifier<double> _liftOffset = ValueNotifier(0);

  static const _dragSlop = 8.0;

  /// Còn dưới ngần này pixel chưa cuộn tới thì vẫn coi như đã ở mép.
  static const _edgeSlack = 24.0;

  /// Mép rộng hơn cho quiz đã chấm — đủ để nuốt phần panel giải thích vừa bung
  /// ra, nhưng vẫn nhỏ hơn một màn nên giải thích dài vẫn cuộn đọc được.
  static const _answeredQuizEdgeSlack = 120.0;

  /// Design's own card-swipe threshold (its pointer handlers commit at 70px).
  static const _swipeThreshold = 70.0;

  /// Design's own card transition: `transform .42s cubic-bezier(.22,.7,.25,1)`.
  /// The 260ms easeOutCubic this used before read as noticeably snappier and
  /// harsher than the prototype.
  static const _snapDuration = Duration(milliseconds: 420);
  static const _snapCurve = Cubic(0.22, 0.7, 0.25, 1);

  /// Vertical padding a card page adds around its card — also the gap between one
  /// card and the next, since adjacent pages sit edge to edge.
  static const _cardVerticalInset = 12.0;

  /// Each page is shorter than the viewport so the neighbouring cards show a
  /// strip of their edge above and below the live one — the design's deck
  /// affordance.
  ///
  /// The shortfall is shared: half above the live page and half below, and each
  /// half pays for that page's own padding first, with the remainder being how
  /// much of the neighbour actually shows. The design wants a 12pt gap plus
  /// ~16pt of visible neighbour, so the shortfall per side needs to be ~22pt —
  /// hence `1 - 2*22/H` for a card area of roughly 700pt. Kept a constant
  /// fraction because [PageController] needs it before any layout has happened;
  /// on taller or shorter screens the strip scales with it.
  static const _peekViewportFraction = 0.937;

  /// Whether the CURRENT card's own content scroller is at its top / bottom
  /// edge. Both default to true: a card whose content fits never emits a scroll
  /// notification at all, and that case must still be swipeable.
  bool _contentAtTop = true;
  bool _contentAtBottom = true;

  /// Số pixel còn lại phía dưới, giữ nguyên giá trị thô để các ngưỡng khác
  /// nhau (thường vs quiz đã chấm) cùng đọc được.
  double _contentExtentAfter = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<KeypointCardCubit>().state.viewedCardIndex,
      viewportFraction: _peekViewportFraction,
    );
    // Post-frame, not here: the wall is read off `CourseRoadmapCubit` /
    // `CourseLessonCubit` / `ProfileCubit`, and it races the narration that
    // starts reading the moment this page mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPaywallCap());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _liftOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KeypointCardCubit, KeypointCardState>(
      listenWhen: (previous, current) => previous.viewedCardIndex != current.viewedCardIndex,
      listener: (context, state) {
        _followViewedCardIndex(state);
        // Backstop. The wall itself lives in `_settleDrag`, which covers the two
        // ways the reader moves the deck; this catches the paths that move it
        // for them — narration following the voice, a tap on the progress pips —
        // landing beyond the wall. It only raises the paywall and deliberately
        // does NOT drag the view back: correcting the index from inside this
        // listener is what read as a stutter.
        final cap = _syncPaywallCap();
        if (cap != null && state.viewedCardIndex > cap) unawaited(_openInLessonPaywall());
      },
      builder: (context, state) {
        if (state.cards.isEmpty) return const SizedBox.shrink();

        final liveDescriptor = state.cards[state.furthestCardIndex];
        final isViewingLive = state.viewedCardIndex == state.furthestCardIndex;
        // Theory cards advance by swiping up (design) — no Continue button.
        // Quiz cards need a deliberate Check commit, but the four exercise types
        // the v2 design covers now draw that button (and their verdict) INSIDE
        // the card, so floating a second one over the deck would double it up.
        final liveBody = liveDescriptor.isQuiz ? _liveQuizBody(context, liveDescriptor) : null;
        final showBottomAction = isViewingLive && liveBody is LessonBodyWidget && !liveBody.rendersOwnAction;
        final isLastCard = state.furthestCardIndex == state.cards.length - 1;

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
                  // below). Each card scrolls its own contents, and Flutter hands
                  // a vertical drag to the innermost scrollable for the whole
                  // gesture — it never re-offers it to an outer vertical
                  // PageView, so physics-driven paging simply cannot fire while
                  // reading. A `Listener` sees pointer moves without entering the
                  // gesture arena, so text scrolling and card swiping coexist
                  // (this is what the design prototype does with its own
                  // onPointerDown/Move/Up handlers).
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
                          // The finger owns the controller from here — any
                          // snap still in flight is abandoned, so its target
                          // must not suppress the follow that settles later.
                          _snapTargetPage = null;
                        },
                        onPointerMove: (event) => _handleDragUpdate(event.delta.dy, state, liveDescriptor),
                        onPointerCancel: (_) {
                          _settleDrag(context, state, liveDescriptor, cancelled: true);
                          KeypointDeckDragLock.reset();
                        },
                        onPointerUp: (_) {
                          _settleDrag(context, state, liveDescriptor);
                          KeypointDeckDragLock.reset();
                        },
                        // Translated during a `lift` drag so the last card
                        // still tracks the finger even though there is no page
                        // beyond it yet — without this the gesture felt dead
                        // until release. Driven by a notifier so the deck below
                        // is never rebuilt mid-gesture, only re-offset.
                        child: ValueListenableBuilder<double>(
                          valueListenable: _liftOffset,
                          builder: (context, liftOffset, child) => Transform.translate(
                            offset: Offset(0, liftOffset),
                            child: child,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // A page box is `viewportFraction` of the viewport
                              // (that shortfall is what lets the neighbours show
                              // an edge), so the card is measured against the
                              // PAGE, not the viewport — measuring the viewport
                              // made every card taller than the page it lives in.
                              final pageHeight = constraints.maxHeight * _peekViewportFraction;
                              return LessonCardMinHeightScope(
                                // Cards are full-height panels (design), not
                                // boxes that shrink to their text.
                                minHeight: math.max(0, pageHeight - _cardVerticalInset),
                                child: PageView.builder(
                                  key: const ValueKey('keypoint-card-page-view'),
                                  controller: _pageController,
                                  scrollDirection: Axis.vertical,
                                  physics: const NeverScrollableScrollPhysics(),
                                  // Reachability, not progress: narration that read
                                  // on while the app was away extends this past the
                                  // lesson's live edge (see `revealBound`).
                                  itemCount: state.revealBound + 1,
                                  // Deliberately NOT wired to `viewCard`. Physics are
                                  // never-scrollable, so every move here is one this
                                  // widget started — and `animateToPage` fires this
                                  // callback for EVERY page it crosses, not just the
                                  // one it lands on. Feeding that back into state made
                                  // one re-sync animation report five card changes,
                                  // each re-pointing narration: the deck appeared to
                                  // scroll at random. Intent flows one way now —
                                  // gesture/narration → state → `_followViewedCardIndex`.
                                  itemBuilder: (context, index) => _KeypointCardStackSlot(
                                    controller: _pageController,
                                    cardIndex: index,
                                    settledIndex: state.viewedCardIndex,
                                    child: _KeypointCardPage(
                                      cardIndex: index,
                                      descriptor: state.cards[index],
                                      isLive: index == state.furthestCardIndex,
                                      isPreview: index > state.furthestCardIndex,
                                      bodyFactory: widget.bodyFactory,
                                      onAnswerChecked: widget.onAnswerChecked,
                                    ),
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
            // The swipe affordance shows on the first two cards only — theory
            // and quiz alike. It teaches a gesture, and once that is learned the
            // pill is pure noise: on a graded quiz card it sat on top of the
            // answer explanation, which is the one thing the reader is there to
            // read.
            if (isViewingLive && state.viewedCardIndex < 2 && liveDescriptor.isTheory)
              _TheorySwipeHintPill(isLastCard: isLastCard)
            else if (isViewingLive && state.viewedCardIndex < 2 && liveDescriptor.isQuiz)
              _SwipeHintPill(blocked: !state.isLiveCardAnswered, isLastCard: isLastCard),
          ],
        );
      },
    );
  }

  /// Remembers whether the card's own content scroller is parked at an edge, so a
  /// swipe only changes card once the user has actually read to the end (or the
  /// content was short enough that there was nothing to scroll).
  ///
  /// [depth] filters out the `PageView`'s own metrics (depth 0): its extents
  /// describe card paging, not the text the user is reading — only the card's
  /// nested content scroller (depth >= 1) answers "have they reached the end?".
  void _applyContentMetrics(ScrollMetrics metrics, int depth) {
    if (depth == 0) return;
    if (metrics.axis != Axis.vertical) return;
    // Dung sai, không phải 1px. Sát-đáy-trong-1-pixel là ngưỡng gắt tới mức
    // lệch nửa pixel do làm tròn cũng đủ nuốt cú vuốt, và người dùng thì đã
    // nhìn thấy hết nội dung từ trước đó rồi.
    _contentAtTop = metrics.extentBefore <= _edgeSlack;
    _contentExtentAfter = metrics.extentAfter;
    _contentAtBottom = metrics.extentAfter <= _edgeSlack;
  }

  /// Claims the gesture on the first meaningful movement, then drags the card
  /// stack with the finger for the rest of it.
  /// Fires the `inLessonPaywall` gate: the reader has just moved off card
  /// `afterCards - 1` onto the next one, which is the moment the config asks for.
  ///
  /// Deliberately does NOT block the deck — the paywall is pushed over the
  /// keypoint and closing it leaves the reader exactly where they were. Once per
  /// Highest card index the reader may reach right now, or `null` when nothing
  /// gates this keypoint.
  ///
  /// `afterCards` counts the cards they are allowed to PASS, so the last
  /// readable index is one less: `afterCards: 1` leaves only card 1 (index 0)
  /// readable, and the wall stands between it and card 2.
  ///
  /// Fails OPEN — any error here returns `null` and the keypoint reads normally.
  /// A paywall that cannot be evaluated must not be able to lock content away.
  ///
  /// Everything comes from `AppDI.injector`, never `context.read`: the lesson
  /// flow's route (`_buildLessonFlowPage`) provides neither `ProfileCubit` nor
  /// `HomeCubit`, so reading either off this context throws
  /// `ProviderNotFoundException`. Both are `@lazySingleton`, so the injector
  /// hands back the very same instances the other routes wrap.
  /// Recomputes the wall and hands it to the deck, which enforces it across
  /// every path that moves the view — not just the reader's swipe.
  ///
  /// Must run before the voice can turn the first card: narration autoplays on
  /// entry (`LessonRoute.initialMode` defaults to `'audio'`), so a cap installed
  /// only on the first swipe arrives after the deck has already been walked past
  /// the wall for the reader.
  int? _syncPaywallCap() {
    final cap = _inLessonPaywallCap();
    if (mounted) context.read<KeypointCardCubit>().setPaywallCardCap(cap);
    return cap;
  }

  int? _inLessonPaywallCap() {
    if (_inLessonPaywallGateBroken) return null;
    try {
      final config = AppDI.injector.get<IapCubit>().resolvedPaywallConfig.inLessonPaywall;
      if (!config.enabled) return null;
      if (AppDI.injector.get<ProfileCubit>().state.user.isPremium) return null;
      if (!_isPaywallGatedKeypoint(config.keypointOrdinal)) return null;
      return config.afterCards - 1;
    } catch (error, stackTrace) {
      _inLessonPaywallGateBroken = true;
      LogDev.error('inLessonPaywall gate failed; leaving this keypoint ungated: $error\n$stackTrace');
      return null;
    }
  }

  /// Whether moving the view to [target] would cross the wall — and if so,
  /// raises the paywall.
  ///
  /// The caller must then leave the deck where it is. Correcting the move
  /// afterwards instead (advance, then snap back) is what made the swipe read
  /// as a stutter: the deck animates forward before anything can pull it back.
  bool _blockedByInLessonPaywall(int target, KeypointCardState state) {
    // Going back is never gated, and neither is staying put.
    if (target <= state.viewedCardIndex) return false;
    final cap = _syncPaywallCap();
    if (cap == null || target <= cap) return false;
    unawaited(_openInLessonPaywall());
    return true;
  }

  /// Raises the in-lesson paywall. The decision to raise it belongs to
  /// [_blockedByInLessonPaywall]; this only performs it.
  Future<void> _openInLessonPaywall() async {
    // Derived, not latched: the gate is closed exactly while an in-lesson
    // paywall is on screen. `PaywallPage.dispose` resets the entry point, so
    // this re-arms the moment the reader dismisses it and the next attempt to
    // move past the walled card raises it again — no bool to get out of step
    // with what is actually displayed.
    final iapCubit = AppDI.injector.get<IapCubit>();
    if (iapCubit.paywallEntryPoint == PaywallEntryPoint.inLesson) return;

    try {
      final courseId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.courseId;
      iapCubit.setPaywallEntryPoint(
        PaywallEntryPoint.inLesson,
        trackingData: CourseTrackingData.fromHomeState(
          AppDI.injector.get<HomeCubit>().state,
          courseId,
        ),
      );

      // Deliberately NOT awaited to decide anything. `PaywallRoute().push`'s
      // future completes as soon as the route is pushed here, not when the
      // reader dismisses it (verified in the route-observer trail: the deck
      // moved back before `didPop` was ever logged), so treating it as "the
      // paywall closed" snapped the deck mid-animation and read as a stutter.
      //
      // Re-arming instead rides on `PaywallEntryPoint`, which `PaywallPage`
      // resets in its own `dispose` — a signal tied to the paywall actually
      // going away.
      unawaited(PaywallRoute().push(context));
    } catch (error, stackTrace) {
      // Raising the paywall runs off a gesture callback. Letting anything escape
      // from here put an exception through the deck's own gesture/listener path,
      // and the deck stopped following the reader — enabling the gate made the
      // lesson unreadable instead of gated. Losing the paywall for this keypoint
      // is an acceptable failure; losing the lesson is not.
      _inLessonPaywallGateBroken = true;
      LogDev.error('inLessonPaywall gate failed; skipping it for this keypoint: $error\n$stackTrace');
    }
  }

  /// Whether the keypoint on screen is at or past the position the config
  /// arms. Position is 1-based over the course's KEYPOINTS in roadmap order —
  /// lesson by lesson, keypoints within each lesson in order — and an ordinal
  /// of 0 arms every keypoint.
  ///
  /// A THRESHOLD (>=), not an exact match (user call, 2026-08-04): a reader
  /// who is already past the configured keypoint — a lapsed premium, or
  /// content resequenced under them — opens keypoint #5 and must still meet
  /// the wall; comparing for equality armed exactly one keypoint of the whole
  /// course and let everyone past it read on free forever.
  ///
  /// This counted LESSONS until the entry-point-variants change: it returned as
  /// soon as it found the lesson containing the current keypoint and compared
  /// that lesson's position, so `keypointOrdinal: 2` armed every keypoint of the
  /// second lesson and none of the first lesson's later keypoints. The admin
  /// panel has always called this field a keypoint position.
  bool _isPaywallGatedKeypoint(int keypointOrdinal) {
    if (keypointOrdinal <= 0) return true;

    final keypointId = AppDI.injector.get<CourseLessonCubit>().state.currentKeypointId;
    if (keypointId.isEmpty) return false;

    final lessons = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.flatLessons;
    var ordinal = 0;
    for (final lesson in lessons) {
      for (final keypoint in lesson.keypoints) {
        ordinal++;
        if (keypoint.id == keypointId) return ordinal >= keypointOrdinal;
      }
    }
    return false;
  }

  void _handleDragUpdate(double delta, KeypointCardState state, KeypointCardDescriptor liveDescriptor) {
    if (!_isDragging) return;
    // A gap-fill chip owns this gesture. The deck reads raw pointer moves
    // through a `Listener` that never enters the gesture arena (see the swipe
    // comment above), so nothing else tells it a `Draggable` already took over:
    // dragging a chip DOWNWARDS resolved to `_DragMode.page` and slid the whole
    // card stack instead of the chip.
    if (KeypointDeckDragLock.isActive) return;
    _dragDy += delta;

    if (_dragMode == null) {
      if (_dragDy.abs() < _dragSlop) return;
      _dragMode = _resolveDragMode(state, liveDescriptor);
      if (_dragMode == _DragMode.page && _pageController.hasClients) {
        _pageStartPixels = _pageController.position.pixels;
      }
    }

    switch (_dragMode!) {
      // The card's own content scroller already moved the text; nothing to do.
      case _DragMode.content:
        return;
      case _DragMode.page:
        if (!_pageController.hasClients) return;
        final position = _pageController.position;
        _pageController.jumpTo((_pageStartPixels - _dragDy).clamp(position.minScrollExtent, position.maxScrollExtent));
      case _DragMode.lift:
        // Elastic: follows the finger at a fraction so it reads as resistance
        // rather than a free page turn into nothing.
        _liftOffset.value = (_dragDy * 0.35).clamp(-90.0, 90.0);
    }
  }

  _DragMode _resolveDragMode(KeypointCardState state, KeypointCardDescriptor liveDescriptor) {
    final isForward = _dragDy < 0;
    if (isForward) {
      // Quiz đã chấm được nới rộng mép, KHÔNG bỏ chặn hẳn. Trả lời xong là
      // panel giải thích bung ra, nội dung dài thêm — người vừa ở đáy bỗng
      // không còn ở đáy và phải cuộn thêm mới vuốt được. Nhưng bỏ chặn hoàn
      // toàn thì mọi cú vuốt lên đều chuyển thẻ, và panel giải thích dài sẽ
      // không còn cách nào cuộn đọc. Nới mép giải quyết đúng phần bực mình mà
      // vẫn giữ được thao tác đọc.
      final atBottomEnough = liveDescriptor.isQuiz && state.isLiveCardAnswered
          ? _contentExtentAfter <= _answeredQuizEdgeSlack
          : _contentAtBottom;
      if (!atBottomEnough) return _DragMode.content;
      // A revealed card ahead means a real page to drag into.
      if (state.viewedCardIndex < state.furthestCardIndex) return _DragMode.page;
      // At the live edge there is no page to drag into yet, so the gesture gets
      // elastic feedback and the card advances on release.
      if (liveDescriptor.isTheory) return _DragMode.lift;
      // A graded quiz leaves by swipe too — that swipe replaced the result
      // sheet's Continue button. An UNANSWERED one must not budge: elastic
      // feedback there made the card ride up behind a gesture that could never
      // complete (the hint pill says why instead).
      if (liveDescriptor.isQuiz && state.isLiveCardAnswered) return _DragMode.lift;
      return _DragMode.content;
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
    _liftOffset.value = 0;
    if (cancelled || mode == null || mode == _DragMode.content) return;

    final committed = dy.abs() >= _swipeThreshold;

    if (mode == _DragMode.page) {
      // Snap: to the neighbour if the drag committed, back to where it started
      // otherwise. The gesture states the intent — it is the only thing that
      // knows a drag committed — and the controller follows from state via
      // [_followViewedCardIndex]. It must NOT animate the controller itself:
      // `onPageChanged` would then be the only thing telling state where the
      // deck went, and it reports every page an animation crosses.
      final target = committed ? state.viewedCardIndex + (dy < 0 ? 1 : -1) : state.viewedCardIndex;
      // A move the paywall refuses is treated exactly like a drag that never
      // reached the threshold — the deck stays put and snaps back, a path this
      // widget already handles — so there is no forward animation to undo.
      final blocked = _blockedByInLessonPaywall(target, state);
      final resolved = blocked ? state.viewedCardIndex : target;
      final clamped = resolved.clamp(0, state.furthestCardIndex);

      // The mode was chosen when the drag BEGAN, with a revealed card ahead. By
      // the time it settles the deck can have caught up to the live edge — the
      // reader swiping faster than cards are revealed, or narration turning a
      // page mid-gesture — and then this clamp collapses the target back onto the
      // card already on screen, `viewCard` sees no change, and the swipe vanishes
      // with no trace. That is the "swiped but it did not move" report; the
      // gesture was committed, it just had nowhere left to land.
      //
      // Hand it to the live-edge path instead, which is the mode this drag would
      // have been given had it started a moment later. The quiz condition mirrors
      // `_resolveDragMode`: an unanswered question still must not budge.
      if (!blocked && committed && dy < 0 && clamped == state.viewedCardIndex) {
        _advanceAtLiveEdge(context, state, liveDescriptor);
        return;
      }

      if (committed && !blocked) AppHaptic.select();
      context.read<KeypointCardCubit>().viewCard(clamped);
      return;
    }

    // lift: only the forward direction has anywhere to go — advance the live
    // card exactly as the old Continue button did. Dragging down on the first
    // card has nothing behind it, so it just springs back (the elastic offset
    // was already reset above).
    if (!committed || dy >= 0) return;
    // The live edge is the other way forward: it does not move the view, it
    // reveals a NEW card (`nextDocument()` / `nextQuestion()`). Walling only the
    // page drag above would leave this wide open — and this is the path that
    // grows `furthestCardIndex`, so letting it through is what makes cards 4, 5,
    // 6 reachable at all.
    if (_blockedByInLessonPaywall(state.viewedCardIndex + 1, state)) return;
    _advanceAtLiveEdge(context, state, liveDescriptor);
  }

  /// Reveals the next card at the live edge on the reader's behalf.
  ///
  /// Releases the entry pin FIRST. This path never calls
  /// `KeypointCardCubit.viewCard` — it reveals a card and lets the deck's
  /// follow-the-edge rule move the view — so with the pin still up the reveal
  /// happened while the view stayed on card 1, and the swipe looked ignored.
  void _advanceAtLiveEdge(
    BuildContext context,
    KeypointCardState state,
    KeypointCardDescriptor liveDescriptor,
  ) {
    // Mirrors `_resolveDragMode`: an unanswered quiz must not budge, and a
    // theory card owing an explanation choice is refused inside
    // `_advanceLiveTheoryCard`. Releasing the pin for a gesture those two turn
    // away is harmless — it only means the view may follow the edge from now on,
    // which is true the moment the reader has tried to move at all.
    context.read<KeypointCardCubit>().releaseEntryPin();
    if (liveDescriptor.isTheory) {
      _advanceLiveTheoryCard(context);
    } else if (liveDescriptor.isQuiz && state.isLiveCardAnswered) {
      _advanceLiveQuizCard();
    }
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

  /// Leaves a graded quiz card. `_resolveDragMode` has already refused the
  /// gesture unless the question carries a result, so there is no second gate
  /// here — this is exactly what the result sheet's Continue button did.
  void _advanceLiveQuizCard() {
    KeypointExerciseAction.trackContinue();
    AppHaptic.select();
    AppDI.injector.get<ExerciseCubit>().nextQuestion();
  }

  /// Page an `animateToPage` from [_followViewedCardIndex] is currently flying
  /// toward, or null. Mid-flight the controller's `page` reads every value the
  /// animation crosses — and a viewport-height change re-maps it entirely — so
  /// rebuilds landing in that window must neither restart the animation nor
  /// mistake the transient reading for a far jump and snap the deck backwards
  /// ("nhảy ngược về card cũ rồi mới đến card cuối", 2026-08-08).
  int? _snapTargetPage;

  void _followViewedCardIndex(KeypointCardState state) {
    // Mid-drag the finger owns the controller (see `_handleDragUpdate`); an
    // animation started from here would fight it.
    if (_isDragging) return;
    if (!_pageController.hasClients) return;
    final targetPage = state.viewedCardIndex;
    if (_pageController.page?.round() == targetPage) {
      _snapTargetPage = null;
      return;
    }
    // Already flying exactly there — let it land.
    if (_snapTargetPage == targetPage) return;

    // The done card is the recap flip card the reader stays on, so arriving
    // there animates like any other neighbour move — no instant jump.

    // Only a genuine neighbour move is animated. A larger gap is not the reader
    // travelling — it is the controller having lost its place: `page` is
    // `pixels / viewportDimension`, and this PageView lives in a LayoutBuilder
    // whose height changes, so the same offset re-maps to a different page (a
    // height that doubles halves the index). Animating across that gap scrolls
    // visibly through cards nobody asked for; jumping restores the page silently.
    final currentPage = _pageController.page?.round();
    if (currentPage != null && (currentPage - targetPage).abs() > 1) {
      _snapTargetPage = null;
      _pageController.jumpToPage(targetPage);
      return;
    }

    _snapTargetPage = targetPage;
    _pageController
        .animateToPage(
          targetPage,
          duration: _snapDuration,
          curve: _snapCurve,
        )
        .whenComplete(() {
          if (_snapTargetPage == targetPage) _snapTargetPage = null;
        });
  }

  /// The exercise body for the live quiz card, built only to ask it questions
  /// (does it draw its own action? what is its bottom button?) — not mounted
  /// here. The mounted copy is the one [_KeypointCardPage] builds.
  Widget _liveQuizBody(BuildContext context, KeypointCardDescriptor descriptor) {
    return widget.bodyFactory.buildExerciseBody(context.read<KeypointCardCubit>().questionForCard(descriptor));
  }

  /// Only reached for the exercise types that still float their action over the
  /// deck — theory advances by swipe and the four designed exercise types draw
  /// their own action, so neither gets here (see `showBottomAction`).
  Widget _liveBottomButton(BuildContext context, KeypointCardDescriptor descriptor) {
    return widget.bodyFactory.buildBottomButton(context, _liveQuizBody(context, descriptor));
  }
}

/// Design's treatment for the cards either side of the live one: dimmed and
/// very slightly shrunk, so the strip of them showing above/below the live card
/// reads as "behind it" rather than as a stray line.
const _kNeighbourOpacity = 0.62;
const _kNeighbourScale = 0.95;

/// The deck position [_KeypointCardStackSlot] dims/scales against, falling back
/// to [settledIndex] on the frames before the controller has dimensions.
///
/// Derived from RAW pixels, deliberately not [PageController.page]: that getter
/// clamps pixels against the position's extents, which lag one layout behind on
/// the listen-mode resume path — the deck is extended and jumped past the old
/// last card in the same emit, so the frame that first builds the revealed
/// cards still reads the OLD last card as the page. The card actually on screen
/// then gets the neighbour treatment (dimmed, shrunk, and its frosted
/// BackdropFilter defeated by the Opacity's saveLayer), and since fixing the
/// extents in layout notifies nobody, it stays dimmed until the next drag.
///
/// Near-integer results are rounded exactly as `_PagePosition.getPageFromPixels`
/// rounds, so a settled deck still hits the slot's `distance == 0` fast path —
/// float dust there would wrap the live card in a saveLayer that breaks its
/// frost even at an imperceptible dim.
@visibleForTesting
double keypointDeckPage(PageController controller, {required int settledIndex}) {
  final hasPosition = controller.hasClients && controller.position.haveDimensions;
  if (!hasPosition) return settledIndex.toDouble();
  final position = controller.position;
  final page = position.pixels / math.max(1.0, position.viewportDimension * controller.viewportFraction);
  final rounded = page.roundToDouble();
  return (page - rounded).abs() < precisionErrorTolerance ? rounded : page;
}

/// Applies that treatment, interpolated against the live scroll position so a
/// card fades and grows into focus as it is dragged in rather than snapping at
/// the page boundary.
///
/// The live card is returned untouched — deliberately, not just as an
/// optimisation: an `Opacity` introduces a `saveLayer`, and a `BackdropFilter`
/// inside one only blurs its own layer, which would break the frosted card's
/// read of the study-theme background. On a thin edge strip that difference is
/// invisible; on the full card it would not be.
class _KeypointCardStackSlot extends StatelessWidget {
  const _KeypointCardStackSlot({
    required this.controller,
    required this.cardIndex,
    required this.settledIndex,
    required this.child,
  });

  final PageController controller;
  final int cardIndex;

  /// Fallback for the frames before the controller has dimensions — its `page`
  /// getter is unusable then, but the cubit always knows which card is showing.
  final int settledIndex;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = keypointDeckPage(controller, settledIndex: settledIndex);
        final distance = (cardIndex - page).abs().clamp(0.0, 1.0);
        if (distance == 0) return child;

        return Opacity(
          opacity: 1 + (_kNeighbourOpacity - 1) * distance,
          child: Transform.scale(
            scale: 1 + (_kNeighbourScale - 1) * distance,
            // Anchored toward the live card (design's transform-origin), so the
            // visible edge holds its position while the rest shrinks away.
            alignment: cardIndex > page ? Alignment.topCenter : Alignment.bottomCenter,
            child: child,
          ),
        );
      },
    );
  }
}

class _KeypointCardPage extends StatelessWidget {
  const _KeypointCardPage({
    required this.cardIndex,
    required this.descriptor,
    required this.isLive,
    required this.isPreview,
    required this.bodyFactory,
    required this.onAnswerChecked,
  });

  final int cardIndex;
  final KeypointCardDescriptor descriptor;
  final bool isLive;

  /// Past the lesson's live edge — a card narration read on to while the app was
  /// off screen. Read-only; see [QuizPreviewCardBody].
  final bool isPreview;

  final LessonBodyFactory bodyFactory;
  final ValueChanged<bool> onAnswerChecked;

  @override
  Widget build(BuildContext context) {
    // Padding is small on purpose: it doubles as the gap to the next card, and
    // the space beyond it belongs to the neighbouring cards' visible edges (see
    // `_peekViewportFraction`).
    final padding = EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h);
    final Widget card = descriptor.isDone
        ? const KeypointDoneCard()
        : descriptor.isTheory
        ? TheoryCardBody(
            cardIndex: cardIndex,
            descriptor: descriptor,
            isLive: isLive,
            onAnswerChecked: onAnswerChecked,
          )
        : QuizCardBody(descriptor: descriptor, isLive: isLive, isPreview: isPreview, bodyFactory: bodyFactory);

    return Padding(padding: padding, child: card);
  }
}

/// Theory flavour of [_SwipeHintPill]: a theory card is held only when it still
/// owes an explanation choice, which `TheoryCubit` owns.
class _TheorySwipeHintPill extends StatelessWidget {
  const _TheorySwipeHintPill({required this.isLastCard});

  final bool isLastCard;

  @override
  Widget build(BuildContext context) {
    final canContinue = context.select((TheoryCubit cubit) => cubit.state.canContinue);
    return _SwipeHintPill(blocked: !canContinue, isLastCard: isLastCard);
  }
}

/// Bottom-centered hint that replaces the removed Continue button as the
/// affordance for advancing a card.
///
/// It says nothing while the card is holding the reader: the card's own CTA
/// already states what is owed (choose an explanation, check the answer), so a
/// second red line under it only nagged about something the button had covered.
class _SwipeHintPill extends StatelessWidget {
  const _SwipeHintPill({required this.blocked, required this.isLastCard});

  final bool blocked;
  final bool isLastCard;

  @override
  Widget build(BuildContext context) {
    if (blocked) return const SizedBox.shrink();

    final label = isLastCard ? context.l10n.lesson.cardSwipeReviewHint : context.l10n.lesson.cardSwipeHint;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 40.h,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLastCard ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 14.sp,
                  color: AppCustomColor.brandPrimary,
                ),
                7.horizontalSpace,
                AppText(label, style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary)),
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
/// The header's narration control, in the design's two states
/// (`11 · Keypoint.dc.html`):
///
/// * **collapsed** (silent) — a 34pt circle with the headphone glyph. Tapping it
///   is the design's `expandAudio`: start playing.
/// * **expanded** (playing) — a 34pt-tall pill holding a speed chip and a pause
///   button. Tapping pause is `collapseAudio`: stop and shrink back to the
///   circle. Tapping the chip opens the speed bubble beneath it.
///
/// Only the collapsed circle existed before; playing just tinted its icon, so the
/// speed control was reachable solely through the overflow menu.
class KeypointNarrationToggle extends StatefulWidget {
  const KeypointNarrationToggle({super.key});

  @override
  State<KeypointNarrationToggle> createState() => _KeypointNarrationToggleState();
}

class _KeypointNarrationToggleState extends State<KeypointNarrationToggle> {
  /// Anchors the speed bubble to the pill. The design places it
  /// `position:absolute; top:42px; right:0` against the control, which an
  /// OverlayPortal reproduces without the header having to reserve room for it.
  final _bubbleController = OverlayPortalController();
  final _bubbleLink = LayerLink();

  /// `OverlayPortalController.hide()` asserts when the controller has never been
  /// attached to a mounted [OverlayPortal] — which is exactly the collapsed state,
  /// where no portal exists. Calling it from the play tap threw inside the gesture
  /// handler, so the button silently did nothing.
  void _hideBubble() {
    if (_bubbleController.isShowing) _bubbleController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final hasUsableSource = context.select((LessonAudioCubit cubit) => cubit.state.hasUsableSource);
    if (!hasUsableSource) return const SizedBox.shrink();

    // Theme-independent, like the rest of the header chrome — see
    // [KeypointHeaderChrome].
    const iconColor = KeypointHeaderChrome.audioOn;

    return BlocBuilder<LessonAudioCubit, LessonAudioState>(
      builder: (context, audioState) {
        final isPlaying = audioState.isPlaying;
        final isLoading = audioState.isLoading;

        // Playing is the design's "expanded": the circle becomes a pill with the
        // speed chip and pause in it. A load in flight keeps the circle (with its
        // spinner) rather than flashing the pill for a few hundred ms.
        if (isPlaying && !isLoading) {
          return CompositedTransformTarget(
            link: _bubbleLink,
            child: _NarrationExpandedPill(
              speed: audioState.speed,
              bubbleController: _bubbleController,
              bubbleLink: _bubbleLink,
              onPause: () {
                _hideBubble();
                _togglePlayback(context, audioState);
              },
            ),
          );
        }

        return Semantics(
          button: true,
          label: context.l10n.lesson.narrationPlaySemantics,
          child: GestureDetector(
            key: const ValueKey('keypoint-card-narration-toggle'),
            behavior: HitTestBehavior.opaque,
            onTap: isLoading
                ? null
                : () {
                    _hideBubble();
                    _togglePlayback(context, audioState);
                  },
            // Same circle as the close and overflow buttons — see
            // [KeypointHeaderButtonChrome]; this used to carry its own copy at a
            // slightly different opacity.
            child: KeypointHeaderButtonChrome(
              child: isLoading
                  ? SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : SvgPicture.asset(
                      // The design's headphone glyph at its 18pt size. Silent, so
                      // it takes the design's `audioOff` grey — the indigo
                      // `audioOn` belongs to the expanded pill.
                      AppAsset.svg.app.icKpHeadphone,
                      width: 18.w,
                      height: 18.w,
                      colorFilter: const ColorFilter.mode(
                        KeypointHeaderChrome.audioOff,
                        BlendMode.srcIn,
                      ),
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
      // The reader's OWN pause — pins the silence, so forward swipes stop
      // auto-restarting narration until they press play again.
      await audioCubit.pause(byUser: true);
      return;
    }

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPlayClick(trackingData);
    }
    await audioCubit.enterAudioMode();
  }
}

/// The playing state of [KeypointNarrationToggle] — the design's expanded pill:
/// `height:34; border-radius:99; background:btn; padding:0 3; gap:2`, holding a
/// speed chip and a pause button.
class _NarrationExpandedPill extends StatelessWidget {
  const _NarrationExpandedPill({
    required this.speed,
    required this.bubbleController,
    required this.bubbleLink,
    required this.onPause,
  });

  final double speed;
  final OverlayPortalController bubbleController;
  final LayerLink bubbleLink;
  final VoidCallback onPause;

  /// `1` rather than `1.0`, `1.25` kept as is — the design's
  /// `(v === 1 ? '1' : String(v)) + 'x'`.
  static String label(double v) => '${v == v.roundToDouble() ? v.toInt() : v}x';

  /// Writes the pick to [KeypointDisplayCubit] rather than straight to
  /// [LessonAudioCubit], because this pill is now the ONLY narration-speed
  /// control (the keypoint settings sheet no longer carries a Speed row).
  ///
  /// `LessonPage` re-applies `readingSpeed` to the player on every keypoint
  /// sync, so a direct `LessonAudioCubit.setSpeed` here would be undone by the
  /// next swipe. Going through the hydrated display cubit is what makes the
  /// choice stick across cards and across app launches — `LessonPage`'s
  /// `readingSpeed` listener pushes it into the player.
  void _setSpeed(double value) {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioSpeedSelect(trackingData, speed: value);
    }
    AppDI.injector.get<KeypointDisplayCubit>().setReadingSpeed(value);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: bubbleController,
      overlayChildBuilder: (_) => _NarrationSpeedBubble(
        link: bubbleLink,
        current: speed,
        onPick: (value) {
          bubbleController.hide();
          _setSpeed(value);
        },
        onDismiss: bubbleController.hide,
      ),
      child: Container(
        height: 34.w,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          color: KeypointHeaderChrome.buttonBg,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: context.l10n.lesson.audioSpeedTitle,
              child: GestureDetector(
                key: const ValueKey('keypoint-card-narration-speed-chip'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptic.select();
                  bubbleController.toggle();
                },
                child: Container(
                  constraints: BoxConstraints(minWidth: 30.w),
                  height: 28.w,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 7.w),
                  decoration: BoxDecoration(
                    color: bubbleController.isShowing ? const Color(0xFF0D121C).withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Text(
                    label(speed),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: KeypointHeaderChrome.icon,
                    ),
                  ),
                ),
              ),
            ),
            2.horizontalSpace,
            Semantics(
              button: true,
              label: context.l10n.lesson.narrationPauseSemantics,
              child: GestureDetector(
                key: const ValueKey('keypoint-card-narration-pause'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  bubbleController.hide();
                  onPause();
                },
                child: SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: Center(
                    // The design's two 4.2x15 rounded bars in a 24 box, at 14pt.
                    child: Icon(Icons.pause_rounded, size: 18.sp, color: KeypointHeaderChrome.icon),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's speed bubble: a white pill `top:42; right:0` under the control,
/// `border-radius:99; padding:4; box-shadow:0 10px 26px rgba(13,18,28,.18)`, with
/// the selected option on `#EEEDFB` in `#554FF0`.
class _NarrationSpeedBubble extends StatelessWidget {
  const _NarrationSpeedBubble({
    required this.link,
    required this.current,
    required this.onPick,
    required this.onDismiss,
  });

  final LayerLink link;
  final double current;
  final ValueChanged<double> onPick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tapping anywhere else closes it, as the design's `closeAll` does.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: Offset(0, 8.h),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(99.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D121C).withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final value in LessonAudioStateX.supportedSpeeds) ...[
                    if (value != LessonAudioStateX.supportedSpeeds.first) 3.horizontalSpace,
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptic.select();
                        onPick(value);
                      },
                      child: Container(
                        constraints: BoxConstraints(minWidth: 34.w),
                        height: 28.w,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: value == current ? const Color(0xFFEEEDFB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                        child: Text(
                          _NarrationExpandedPill.label(value),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: value == current ? FontWeight.w800 : FontWeight.w600,
                            color: value == current ? KeypointHeaderChrome.audioOn : const Color(0xFF3A4250),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
