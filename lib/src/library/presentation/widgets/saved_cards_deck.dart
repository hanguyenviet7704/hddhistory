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

class _SavedCardsDeckState extends State<SavedCardsDeck> with SingleTickerProviderStateMixin {
  final GlobalKey _shareBoundaryKey = GlobalKey();

  int _index = 0;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _turn = CurvedAnimation(
    parent: _flip,
    curve: const Cubic(0.2, 0.7, 0.25, 1),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  SavedCardEntity? get _card => _index < widget.cards.length ? widget.cards[_index] : null;

  @override
  void didUpdateWidget(covariant SavedCardsDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A card removed elsewhere (the detail overlay, another screen) can leave
    // the cursor past the end — land on the new last card rather than on blank.
    if (_index >= widget.cards.length && widget.cards.isNotEmpty) {
      setState(() => _index = widget.cards.length - 1);
    }
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.cards.length) return;
    AppHaptic.select();
    setState(() => _index = next);
    // Every card arrives face up: carrying the flip across would show the next
    // card's recap before its quote, which is the wrong way round.
    _flip.value = 0;
  }

  void _toggleFlip() {
    final card = _card;
    if (card == null || !card.canFlip || _flip.isAnimating) return;
    AppHaptic.select();
    _flip.value > 0.5 ? _flip.reverse() : _flip.forward();
  }

  Future<void> _share() async {
    final card = _card;
    if (card == null) return;
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, floatingNavBarHeight(context) + 20.h),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleFlip,
            // Sideways only: the page itself scrolls vertically, and claiming
            // the vertical axis here would trap the reader on the deck.
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 120) return;
              _step(velocity < 0 ? 1 : -1);
            },
            child: _DeckStack(
              shareBoundaryKey: _shareBoundaryKey,
              card: card,
              turn: _turn,
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
class _DeckStack extends StatelessWidget {
  const _DeckStack({
    required this.shareBoundaryKey,
    required this.card,
    required this.turn,
  });

  final GlobalKey shareBoundaryKey;
  final SavedCardEntity card;
  final Animation<double> turn;

  @override
  Widget build(BuildContext context) {
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
                left: 14.w,
                right: 14.w,
                top: 16.h,
                bottom: -16.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBF9),
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
              ),
              Positioned(
                left: 7.w,
                right: 7.w,
                top: 8.h,
                bottom: -8.h,
                child: DecoratedBox(
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
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  key: shareBoundaryKey,
                  child: SavedFlipCard(card: card, turn: turn),
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
