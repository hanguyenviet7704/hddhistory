part of '../../library.dart';

/// The deck view of Saved cards (design `5b · Library` → "Saved cards · Deck"):
/// one card at a time on a stack of two paper layers, swiped sideways and
/// flipped by tapping.
class SavedCardsDeck extends StatefulWidget {
  const SavedCardsDeck({super.key, required this.cards, required this.toast});

  final List<SavedCardEntity> cards;
  final SavedToastController toast;

  @override
  State<SavedCardsDeck> createState() => _SavedCardsDeckState();
}

/// Past this fraction of the card's width, letting go sends the card on its way
/// rather than springing it back.
const double _kDeckCommitFraction = 0.35;

/// A flick faster than this commits regardless of how far it travelled.
const double _kDeckCommitVelocity = 600;

/// How far the card has to travel for the stack behind it to finish rising —
/// well short of the commit distance, so the next card is already coming
/// forward while the reader is still deciding.
const double _kDeckRiseFraction = 0.4;

/// Resistance when dragging past the first or the last card. Not zero: a dead
/// card reads as a frozen screen, a heavy one reads as the end of the deck.
const double _kDeckOverrunDamping = 0.3;

class _SavedCardsDeckState extends State<SavedCardsDeck> with TickerProviderStateMixin {
  final GlobalKey _shareBoundaryKey = GlobalKey();

  int _index = 0;

  /// Live horizontal offset of the front card — the finger's, then the settle
  /// animation's.
  double _dragX = 0;

  /// Card width as laid out this frame. The gesture handlers need it to size
  /// their thresholds, and they run after build.
  double _cardWidth = 1;

  /// Where the current settle animation runs between, in [_dragX] units.
  double _settleFrom = 0;
  double _settleTarget = 0;

  /// Index delta to apply once the outgoing card has left the screen. Zero
  /// while springing back.
  int _pendingStep = 0;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _turn = CurvedAnimation(
    parent: _flip,
    curve: const Cubic(0.2, 0.7, 0.25, 1),
  );

  /// Drives [_dragX] after the finger lifts. Unbounded so the spring can
  /// overshoot past its target and bounce back instead of stopping dead.
  late final AnimationController _settle = AnimationController.unbounded(vsync: this)..addListener(_onSettleTick);

  static const SpringDescription _spring = SpringDescription(mass: 1, stiffness: 500, damping: 30);

  @override
  void dispose() {
    _flip.dispose();
    _settle
      ..removeListener(_onSettleTick)
      ..dispose();
    super.dispose();
  }

  SavedCardEntity? get _card => _index < widget.cards.length ? widget.cards[_index] : null;

  /// The card sitting immediately behind the front one — whichever way the
  /// drag is heading. Dragging LEFT pulls the next card in, dragging RIGHT
  /// brings the previous one back.
  ///
  /// At rest it resolves to the next card, which is invisible anyway (the front
  /// card covers all but a 7px strip of it), so the swap on the first pixel of
  /// a rightward drag is never seen.
  SavedCardEntity? get _neighbourCard {
    final offset = _dragX > 0 ? -1 : 1;
    final index = _index + offset;
    if (index < 0 || index >= widget.cards.length) return null;
    return widget.cards[index];
  }

  @override
  void didUpdateWidget(covariant SavedCardsDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A card removed elsewhere (the detail overlay, another screen) can leave
    // the cursor past the end — land on the new last card rather than on blank.
    if (_index >= widget.cards.length && widget.cards.isNotEmpty) {
      setState(() => _index = widget.cards.length - 1);
    }
    // The list changed under a card that was mid-flight: finish where it is
    // rather than committing a step against indexes that have moved.
    if (oldWidget.cards.length != widget.cards.length) _cancelSettle(resetOffset: true);
  }

  // ------------------------------------------------------------------ drag

  void _onDragStart(DragStartDetails details) {
    // Catching a card mid-settle hands it straight back to the finger.
    _cancelSettle();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final proposed = _dragX + details.delta.dx;
    final atStart = _index == 0;
    final atEnd = _index >= widget.cards.length - 1;
    // Dragging right on the first card, or left on the last, has nowhere to go.
    final overruns = (atStart && proposed > 0) || (atEnd && proposed < 0);

    setState(() => _dragX += details.delta.dx * (overruns ? _kDeckOverrunDamping : 1));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragX == 0) return;

    final velocity = details.primaryVelocity ?? 0;
    final flicked = velocity.abs() > _kDeckCommitVelocity;
    // A flick decides its own direction — the reader can drag one way, change
    // their mind, and throw the card back the other.
    final direction = flicked ? (velocity < 0 ? 1 : -1) : (_dragX < 0 ? 1 : -1);
    final committed = flicked || _dragX.abs() > _cardWidth * _kDeckCommitFraction;
    final canStep = direction > 0 ? _index < widget.cards.length - 1 : _index > 0;

    if (committed && canStep) {
      _flingOut(direction);
    } else {
      _springBack(velocity);
    }
  }

  /// Sends the card the rest of the way off screen, then swaps in the next one.
  void _flingOut(int direction) {
    AppHaptic.select();
    _pendingStep = direction;
    _settleFrom = _dragX;
    // Past the far edge of the frame, so nothing of the card is still visible
    // when it is replaced.
    _settleTarget = -direction * (MediaQuery.sizeOf(context).width + _cardWidth);
    _settle
      ..value = 0
      ..animateTo(1, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  void _springBack(double velocity) {
    _pendingStep = 0;
    _settleFrom = _dragX;
    _settleTarget = 0;
    // The spring runs 0 → 1 over the whole return trip, so the finger's
    // velocity has to be expressed in the same units to carry through.
    final normalized = _dragX == 0 ? 0.0 : -velocity / _dragX;
    _settle
      ..value = 0
      ..animateWith(SpringSimulation(_spring, 0, 1, normalized));
  }

  void _onSettleTick() {
    // Reached the far edge: the card is out of sight, so this is the one frame
    // where the swap is invisible. Doing it any earlier — at the moment the
    // gesture ends, as a snapping deck can — would show the card un-flip and
    // change its title in mid-air.
    if (_pendingStep != 0 && _settle.value >= 1) {
      final next = _index + _pendingStep;
      _pendingStep = 0;
      _settle.stop();
      setState(() {
        _index = next;
        _dragX = 0;
      });
      // Every card arrives face up: carrying the flip across would show the
      // next card's recap before its quote, which is the wrong way round.
      _flip.value = 0;
      return;
    }

    setState(() => _dragX = ui.lerpDouble(_settleFrom, _settleTarget, _settle.value) ?? 0);
  }

  void _cancelSettle({bool resetOffset = false}) {
    _settle.stop();
    _pendingStep = 0;
    if (resetOffset && _dragX != 0) setState(() => _dragX = 0);
  }

  void _toggleFlip() {
    final card = _card;
    if (card == null || !card.canFlip || _flip.isAnimating) return;
    AppHaptic.select();
    _flip.value > 0.5 ? _flip.reverse() : _flip.forward();
  }

  /// Opens the share sheet rather than firing the OS share directly: a card can
  /// go INTO Confession as a post, and that destination has no place in the
  /// system sheet.
  Future<void> _share() async {
    final card = _card;
    if (card == null) return;

    await showSavedCardShareSheet(
      context,
      card: card,
      onShareImage: _shareImage,
    );
  }

  Future<void> _shareImage() async {
    final card = _card;
    if (card == null || !mounted) return;

    final ok = await shareSavedQuoteCard(
      context,
      boundaryKey: _shareBoundaryKey,
      title: card.displayTitle,
    );
    if (!mounted || ok) return;
    widget.toast.show(context.l10n.library.shareFailed);
  }

  Future<void> _toggleSave() async {
    final card = _card;
    if (card == null) return;
    final l10n = context.l10n.library;
    final saved = await context.read<SavedCubit>().toggleCard(
      SaveCardParams(
        keypointId: card.keypointId,
        lessonId: card.lessonId,
        courseId: card.courseId,
        // Trả lại nguyên bản đa ngôn ngữ khi lưu lại, nếu không một lần bỏ
        // lưu rồi lưu lại sẽ hạ thẻ xuống còn một thứ tiếng.
        recap: card.recap,
        recapText: card.recapText,
      ),
    );
    if (!mounted) return;
    widget.toast.show(saved ? l10n.cardSavedToast : l10n.cardRemovedToast);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();

    final isSaved = context.select<SavedCubit, bool>(
      (cubit) => cubit.state.isCardSaved(card.keypointId),
    );
    final l10n = context.l10n.library;
    _cardWidth = math.min(330.w, MediaQuery.sizeOf(context).width - 40.w);
    final riseProgress = (_dragX.abs() / (_cardWidth * _kDeckRiseFraction)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, floatingNavBarHeight(context) + 20.h),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleFlip,
            // Sideways only: the page itself scrolls vertically, and claiming
            // the vertical axis here would trap the reader on the deck.
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: _DeckStack(
              shareBoundaryKey: _shareBoundaryKey,
              card: card,
              nextCard: _neighbourCard,
              turn: _turn,
              dragX: _dragX,
              cardWidth: _cardWidth,
              riseProgress: riseProgress,
            ),
          ),
          // The two paper layers below the card hang 16 past its foot; the pips
          // clear them rather than sitting on top.
          44.verticalSpace,
          _DeckPips(count: widget.cards.length, index: _index),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SavedCardActionButton.share(
                key: const Key('saved-deck-share'),
                semanticsLabel: l10n.shareLabel,
                background: _kSavedTileGrey,
                onTap: () => unawaited(_share()),
              ),
              10.horizontalSpace,
              SavedCardActionButton.bookmark(
                key: const Key('saved-deck-bookmark'),
                semanticsLabel: isSaved ? l10n.unsaveCardLabel : l10n.saveCardLabel,
                isSaved: isSaved,
                background: _kSavedTileGrey,
                onTap: () => unawaited(_toggleSave()),
              ),
            ],
          ),
          14.verticalSpace,
          AppText(
            l10n.deckHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: studyThemeOnBg(context, AppCustomColor.textTertiary),
            ),
          ),
          14.verticalSpace,
          SavedToastHost(controller: widget.toast),
        ],
      ),
    );
  }
}

/// The card and the two paper layers behind it.
///
/// As the front card is dragged away the two layers advance one step each
/// ([riseProgress]), so the next card is visibly coming forward rather than the
/// top one merely sliding off a static backdrop. That rise is most of what
/// makes the stack read as a deck of paper.
class _DeckStack extends StatelessWidget {
  const _DeckStack({
    required this.shareBoundaryKey,
    required this.card,
    required this.nextCard,
    required this.turn,
    required this.dragX,
    required this.cardWidth,
    required this.riseProgress,
  });

  final GlobalKey shareBoundaryKey;
  final SavedCardEntity card;

  /// The card being pulled towards — whichever neighbour the drag is heading
  /// for. Null at the ends of the deck, where nothing is behind.
  final SavedCardEntity? nextCard;
  final Animation<double> turn;
  final double dragX;
  final double cardWidth;
  final double riseProgress;

  /// How far the card tilts at a full card-width of travel — a card pulled out
  /// of a stack pivots, it does not track sideways like a scroll view.
  static const double _maxTiltRadians = 0.12;

  @override
  Widget build(BuildContext context) {
    final t = riseProgress;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 330.w),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            // The layers deliberately hang below the card — clipping them to the
            // card's box is what would make the stack read as one flat sheet.
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: ui.lerpDouble(14.w, 7.w, t),
                right: ui.lerpDouble(14.w, 7.w, t),
                top: ui.lerpDouble(16.h, 8.h, t),
                bottom: ui.lerpDouble(-16.h, -8.h, t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBF9),
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
              ),
              Positioned(
                left: ui.lerpDouble(7.w, 0, t),
                right: ui.lerpDouble(7.w, 0, t),
                top: ui.lerpDouble(8.h, 0, t),
                bottom: ui.lerpDouble(-8.h, 0, t),
                // The card the reader is pulling towards, drawn for real. A
                // blank sheet here is what made the swipe feel like it led
                // nowhere — half way across you were looking at an empty box.
                // At rest this is hidden behind the front card save for a 7px
                // strip of its own white margin, so the deck still reads as the
                // design's plain stack until a drag starts.
                child: nextCard == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F5FD),
                          borderRadius: BorderRadius.circular(27.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF141828).withValues(alpha: 0.06),
                              blurRadius: 18.r,
                              offset: Offset(0, 6.h),
                            ),
                          ],
                        ),
                      )
                    : SavedQuoteCard(
                        // Keyed on the card so Flutter rebuilds rather than
                        // reuses when the revealed neighbour flips from the one
                        // ahead to the one behind mid-drag.
                        key: ValueKey(nextCard!.keypointId),
                        title: nextCard!.displayTitle,
                        courseTitle: nextCard!.courseTitle.text,
                        imageUrl: nextCard!.image,
                      ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(dragX, 0),
                  child: Transform.rotate(
                    angle: dragX / cardWidth * _maxTiltRadians,
                    // The boundary sits UNDER the transforms on purpose: a share
                    // capture reads the boundary's own subtree, so the picture
                    // is the card square-on however it happens to be sitting.
                    child: RepaintBoundary(
                      key: shareBoundaryKey,
                      child: SavedFlipCard(card: card, turn: turn),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card, turning. Shared by the deck and the detail overlay so the two
/// cannot end up with different flip physics.
class SavedFlipCard extends StatelessWidget {
  const SavedFlipCard({super.key, required this.card, required this.turn});

  final SavedCardEntity card;
  final Animation<double> turn;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: turn,
      builder: (context, _) {
        final angle = turn.value * math.pi;
        final showBack = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          // The perspective entry is what reads as a card turning in space
          // rather than squashing flat (design: perspective 1200).
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateY(angle),
          child: showBack
              // Pre-mirrored so the back reads left-to-right once past the edge.
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: SavedQuoteCardBack(
                    title: card.displayTitle,
                    body: card.backText,
                  ),
                )
              : SavedQuoteCard(
                  title: card.displayTitle,
                  courseTitle: card.courseTitle.text,
                  imageUrl: card.image,
                ),
        );
      },
    );
  }
}

/// Position in the deck. The active pip stretches rather than changing colour
/// alone — at 6px a colour-only cue is easy to miss.
class _DeckPips extends StatelessWidget {
  const _DeckPips({required this.count, required this.index});

  final int count;
  final int index;

  /// Above this the row of dots stops being readable and starts being noise.
  static const int _maxPips = 12;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    if (count > _maxPips) {
      return AppText(
        '${index + 1}/$count',
        style: TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: studyThemeOnBg(context, AppCustomColor.textTertiary),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.5.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (isActive ? 18.0 : 6.0).w,
            height: 6.h,
            decoration: BoxDecoration(
              color: isActive ? AppCustomColor.brandPrimary : _kQuoteHexRing,
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
        );
      }),
    );
  }
}
