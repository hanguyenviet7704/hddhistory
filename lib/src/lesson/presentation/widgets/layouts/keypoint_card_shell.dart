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

  /// One `inLessonPaywall` open per keypoint — see [_maybeOpenInLessonPaywall].
  bool _hasOpenedInLessonPaywall = false;

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
        _maybeOpenInLessonPaywall(state);
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
                                  onPageChanged: (index) => context.read<KeypointCardCubit>().viewCard(index),
                                  itemBuilder: (context, index) => _KeypointCardStackSlot(
                                    controller: _pageController,
                                    cardIndex: index,
                                    settledIndex: state.viewedCardIndex,
                                    child: _KeypointCardPage(
                                      cardIndex: index,
                                      descriptor: state.cards[index],
                                      isLive: index == state.furthestCardIndex,
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
  /// keypoint open (this State lives as long as the deck), so backing out and
  /// re-entering the keypoint can show it again but scrolling back and forth
  /// cannot.
  void _maybeOpenInLessonPaywall(KeypointCardState state) {
    if (_hasOpenedInLessonPaywall) return;

    final iapCubit = AppDI.injector.get<IapCubit>();
    final config = iapCubit.resolvedPaywallConfig.inLessonPaywall;
    if (!config.enabled) return;
    if (state.viewedCardIndex < config.afterCards) return;
    if (context.read<ProfileCubit>().state.user.isPremium) return;
    if (!_isPaywallGatedKeypoint(config.keypointOrdinal)) return;

    _hasOpenedInLessonPaywall = true;
    final courseId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.courseId;
    iapCubit.setPaywallEntryPoint(
      PaywallEntryPoint.inLesson,
      trackingData: CourseTrackingData.fromCourseId(context, courseId),
    );
    PaywallRoute().push(context);
  }

  /// Whether the keypoint on screen is the one the config arms. Position is
  /// 1-based over the course's flat lesson list — the same ordering `lessonLock`
  /// counts in — and an ordinal of 0 arms every keypoint.
  bool _isPaywallGatedKeypoint(int keypointOrdinal) {
    if (keypointOrdinal <= 0) return true;

    final keypointId = AppDI.injector.get<CourseLessonCubit>().state.currentKeypointId;
    if (keypointId.isEmpty) return false;

    final lessons = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.flatLessons;
    for (var index = 0; index < lessons.length; index++) {
      if (lessons[index].keypoints.any((keypoint) => keypoint.id == keypointId)) {
        return index + 1 == keypointOrdinal;
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
      // otherwise. `onPageChanged` reports the landing card, which is what
      // moves narration (see `KeypointCardCubit.viewCard`).
      final target = committed ? state.viewedCardIndex + (dy < 0 ? 1 : -1) : state.viewedCardIndex;
      if (committed) AppHaptic.select();
      unawaited(
        _pageController.animateToPage(
          target.clamp(0, state.furthestCardIndex),
          duration: _snapDuration,
          curve: _snapCurve,
        ),
      );
      return;
    }

    // lift: only the forward direction has anywhere to go — advance the live
    // card exactly as the old Continue button did. Dragging down on the first
    // card has nothing behind it, so it just springs back (the elastic offset
    // was already reset above).
    if (!committed || dy >= 0) return;
    if (liveDescriptor.isTheory) {
      _advanceLiveTheoryCard(context);
    } else if (liveDescriptor.isQuiz) {
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
      duration: _snapDuration,
      curve: _snapCurve,
    );
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
        final hasPosition = controller.hasClients && controller.position.haveDimensions;
        final page = hasPosition ? (controller.page ?? settledIndex.toDouble()) : settledIndex.toDouble();
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
        : QuizCardBody(descriptor: descriptor, isLive: isLive, bodyFactory: bodyFactory);

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
class KeypointNarrationToggle extends StatelessWidget {
  const KeypointNarrationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUsableSource = context.select((LessonAudioCubit cubit) => cubit.state.hasUsableSource);
    if (!hasUsableSource) return const SizedBox.shrink();

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
