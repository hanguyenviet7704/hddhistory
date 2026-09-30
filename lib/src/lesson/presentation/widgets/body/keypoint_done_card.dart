part of '../../../lesson.dart';

/// Terminal card of the unified keypoint swipe screen — the design's recap flip
/// card (`_MeUp App` → `RECAP (flip cards)` / `_Keypoint Swipe Lab` → `c.isPeek`):
/// the keypoint restated as a white quote card that FLIPS on tap to a dark card
/// carrying the recap text, with Continue at the bottom.
///
/// This card used to be a checkmark visible for a frame or two:
/// [LessonCubit.completeCurrentKeypoint] navigated to [KeypointCompleteRoute]
/// the instant the last real card finished, covering it. Completion still fires
/// exactly then (progress written, Live Activity updated, `completionOrigin`
/// set — nothing about WHAT completing means changed), but navigation now waits
/// for Continue here, which hands over to the lesson-complete screen — where
/// the practice entry lives ("Practice now" → [PracticeHubPage]).
///
/// The recap text is the keypoint's authored takeaway — the "Take This With
/// You" summary theory item ([TakeawaySummaryItemX]), which no longer renders
/// as a deck card precisely because it lives here. Keypoints without one fall
/// back to `description`; with neither, the quote card keeps its front but
/// loses the flip and its hint — a card that flips to nothing teaches the
/// reader the gesture is a lie.
///
/// The explicit completion call below is a fallback for the one path where
/// nothing else would have triggered completion: a keypoint with no content at
/// all.
class KeypointDoneCard extends StatefulWidget {
  const KeypointDoneCard({super.key});

  @override
  State<KeypointDoneCard> createState() => _KeypointDoneCardState();
}

class _KeypointDoneCardState extends State<KeypointDoneCard> with SingleTickerProviderStateMixin {
  /// Continue is resolving the habit step (network) — the button shows a
  /// spinner and ignores taps for that beat.
  bool _isContinuing = false;

  /// Wraps the flip card so Share can hand the reader a picture of the card
  /// itself rather than a line of text about it.
  final GlobalKey _shareBoundaryKey = GlobalKey();

  /// "Saved to your cards" / "Removed", in the same 38-tall slot the actions
  /// live in — the design keeps the answer next to the button that caused it.
  final SavedToastController _toast = SavedToastController();

  /// 0 → front (quote), 1 → back (recap text). The design's
  /// `transition: transform .6s cubic-bezier(.2,.7,.25,1)`.
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _turn = CurvedAnimation(
    parent: _flip,
    curve: const Cubic(0.2, 0.7, 0.25, 1),
  );

  @override
  void initState() {
    super.initState();
    // The PageView disposes this State when the card scrolls far enough away;
    // a recap the reader already opened must come back OPEN, without replaying
    // the flip (and without the celebrate haptic firing again).
    final alreadyOpened = context.read<KeypointCardCubit>().recapFlipOpened;
    if (alreadyOpened) {
      _flip.value = 1;
      _autoFlipped = true;
    } else {
      AppHaptic.celebrate();
    }
    // Without the id set, the bookmark would draw hollow on a card the reader
    // already saved — and a second tap would then UNSAVE it.
    unawaited(AppDI.injector.get<SavedCubit>().ensureIdsLoaded());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lessonCubit = context.read<LessonCubit>();
      if (lessonCubit.state.completionOrigin == LessonCompletionOrigin.none) {
        lessonCubit.completeCurrentKeypoint();
      }
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _toast.dispose();
    super.dispose();
  }

  /// Shares the card as a picture. Captures whichever face is showing — a
  /// reader who flipped to the recap and pressed share meant the recap.
  Future<void> _share(String keypointTitle) async {
    final ok = await shareSavedQuoteCard(
      context,
      boundaryKey: _shareBoundaryKey,
      title: keypointTitle,
    );
    if (!mounted || ok) return;
    _toast.show(context.l10n.library.shareFailed);
  }

  /// Keeps this card in Library → Saved cards.
  ///
  /// The recap text travels with the save: it is derived HERE from the lesson's
  /// items ([resolveTakeawaySummary]) and the server has no way to re-derive it
  /// — see [SavedCardEntity].
  Future<void> _toggleSave({required BaseMultiLanguage recap, required String recapText}) async {
    final lessonState = context.read<CourseLessonCubit>().state;
    final keypointId = lessonState.currentKeypointId;
    if (keypointId.isEmpty) return;
    // The button is hidden for these (see [_recapActions]); refuse here too so a
    // future caller cannot re-introduce a row Saved cards can never resolve.
    if (lessonState.selectedLesson.isImported) return;

    final l10n = context.l10n.library;
    final saved = await AppDI.injector.get<SavedCubit>().toggleCard(
      SaveCardParams(
        keypointId: keypointId,
        lessonId: lessonState.selectedLesson.id,
        courseId: lessonState.selectedLesson.courseId,
        // Lưu ĐỦ năm tiếng, không chỉ tiếng đang hiện: đổi ngôn ngữ app xong
        // mở lại thẻ trong Thư viện phải ra đúng ngôn ngữ mới.
        recap: recap,
        recapText: recapText,
      ),
    );
    if (!mounted) return;
    _toast.show(saved ? l10n.cardSavedToast : l10n.cardRemovedToast);
  }

  void _toggleFlip(bool hasRecap) {
    if (!hasRecap || _flip.isAnimating) return;
    AppHaptic.select();
    final flippingForward = !(_flip.isCompleted || _flip.value > 0.5);
    // Forward only: opening the recap is the action the sheet counts; flipping
    // back to the quote is not. The narration-driven auto-flip
    // ([_maybeAutoFlip]) doesn't pass through here, so it stays untracked —
    // this is a TAP event.
    if (flippingForward) LessonTracking.recapTap();
    flippingForward ? _flip.forward() : _flip.reverse();
    // The open/closed face survives this State (see initState) — a reader who
    // closed it back to the quote gets the quote back too.
    context.read<KeypointCardCubit>().recapFlipOpened = flippingForward;
    // The in-app listening flow parks the voice on arriving at this card and
    // waits for exactly this tap — OPENING the recap reads it out. Closing it
    // back to the quote face stays quiet, and so does flipping when nothing
    // was gated.
    if (flippingForward) context.read<KeypointCardCubit>().resumeRecapNarrationIfGated();
  }

  /// Narration is reading THIS card's text (the takeaway clip) once, so show
  /// the face that carries it. Only ever fires forward, and only once — a
  /// reader who flips back to the quote mid-listen is not fought over it.
  bool _autoFlipped = false;

  /// The listened-through keypoint has already been carried onward, so the
  /// signal (which stays true until the next clip loads) cannot fire twice.
  bool _autoContinued = false;

  /// A keypoint heard to its end needs no Continue tap: background listening
  /// reads straight through the recap gate, so a reader coming back to the app
  /// would otherwise find a finished keypoint still asking to be dismissed by
  /// hand. Hands over to the very same [_continue] the button runs — habit
  /// suggestions when there are any, the lesson-complete screen otherwise.
  void _maybeAutoContinue({required bool isViewed}) {
    if (_autoContinued || _isContinuing || !isViewed) return;
    if (!context.read<KeypointCardCubit>().narrationFinishedKeypoint) return;
    _autoContinued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_continue());
    });
  }

  void _maybeAutoFlip({required bool hasRecap, required bool isViewed, required bool isNarrating}) {
    if (_autoFlipped || !hasRecap || !isViewed || !isNarrating) return;
    _autoFlipped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _flip.isAnimating || _flip.value > 0) return;
      _flip.forward();
      context.read<KeypointCardCubit>().recapFlipOpened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseLessonState = context.watch<CourseLessonCubit>().state;
    final keypoint = courseLessonState.resolvedCurrentKeypoint;
    final keypointTitle = keypoint.title.text.isNotEmpty ? keypoint.title.text : courseLessonState.selectedLesson.title.text;
    final lessonTitle = courseLessonState.selectedLesson.title.text;
    final imageUrl = keypoint.image.isNotEmpty ? keypoint.image : courseLessonState.selectedLesson.image;
    final lessonItems = context.watch<LessonCubit>().state.pageData.items;
    final takeaway = resolveTakeawaySummary(lessonItems);
    // Giữ cả bản đa ngôn ngữ (để LƯU) lẫn bản đã chọn ngôn ngữ (để HIỆN).
    final takeawayMulti = takeaway.exists ? lessonItems[takeaway.itemIndex].takeawaySummary : const BaseMultiLanguage();
    final takeawayText = takeawayMulti.text;
    final recapMulti = takeawayText.isNotEmpty ? takeawayMulti : keypoint.description;
    final recapText = takeawayText.isNotEmpty ? takeawayText : keypoint.description.text.trim();
    final hasRecap = recapText.isNotEmpty;

    // Narration reads the takeaway itself while this card is the viewed one →
    // flip to the face being read. Keyed on the takeaway CUE, not on "audio is
    // playing": swiping ahead onto this card mid-listen must not flip it out
    // of the reader's hands. (The audio-cubit watch is what makes this line
    // re-evaluate as playback state changes.)
    context.watch<LessonAudioCubit>();
    final deckState = context.watch<KeypointCardCubit>().state;
    final isViewedCard = deckState.cards.isNotEmpty && deckState.viewedCardIndex == deckState.cards.length - 1;
    final isNarrating = context.read<KeypointCardCubit>().isNarratingRecap;
    _maybeAutoFlip(hasRecap: hasRecap, isViewed: isViewedCard, isNarrating: isNarrating);
    _maybeAutoContinue(isViewed: isViewedCard);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          const Spacer(),
          // The share capture takes THIS subtree, so the boundary sits around
          // the card and nothing else — the picture is the card, not the screen.
          RepaintBoundary(
            key: _shareBoundaryKey,
            child: GestureDetector(
              onTap: () => _toggleFlip(hasRecap),
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) {
                  final angle = _turn.value * math.pi;
                  final showBack = angle > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    // The slight perspective entry is what reads as a card turning
                    // in space rather than squashing flat (design: perspective 1400).
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateY(angle),
                    child: showBack
                        // Pre-mirrored so the back face reads left-to-right once
                        // the card has turned past its edge.
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _recapBack(context, keypointTitle: keypointTitle, recapText: recapText),
                          )
                        : _quoteFront(context, keypointTitle: keypointTitle, lessonTitle: lessonTitle, imageUrl: imageUrl),
                  );
                },
              ),
            ),
          ),
          16.verticalSpace,
          _hintAndActions(context, hasRecap: hasRecap, keypointTitle: keypointTitle, recap: recapMulti, recapText: recapText),
          const Spacer(),
          SavedToastHost(controller: _toast),
          8.verticalSpace,
          _continueButton(context),
          12.verticalSpace,
        ],
      ),
    );
  }

  /// One slot under the card holding two things that swap as it turns (design
  /// `_MeUp App` → RECAP): "Tap to see the recap" on the front, Share + Save on
  /// the back.
  ///
  /// They cross-fade in place rather than stacking vertically, which is what
  /// keeps Continue from moving when the card flips.
  ///
  /// The slot is 44 tall, not the design's 38: a 38 disc is under the minimum
  /// tap target, so the buttons carry a 44 gesture box around their drawn size
  /// and the row has to be tall enough to hold it.
  Widget _hintAndActions(
    BuildContext context, {
    required bool hasRecap,
    required String keypointTitle,
    required BaseMultiLanguage recap,
    required String recapText,
  }) {
    final actions = _recapActions(context, keypointTitle: keypointTitle, recap: recap, recapText: recapText);

    // Nothing to flip TO — the card never turns, so the hint would be a lie and
    // the cross-fade has nothing to fade between. Show the actions outright,
    // rather than leaving a keypoint with no takeaway impossible to save.
    if (!hasRecap)
      return SizedBox(
        height: 44.h,
        child: Center(child: actions),
      );

    return SizedBox(
      height: 44.h,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) {
          final front = (1 - _turn.value).clamp(0.0, 1.0);
          final back = _turn.value.clamp(0.0, 1.0);
          final showingBack = _turn.value > 0.5;

          return Stack(
            alignment: Alignment.center,
            children: [
              // IgnorePointer on the hidden face: a fully faded row still takes
              // taps, and the invisible one sits exactly on top of the visible.
              IgnorePointer(
                ignoring: showingBack,
                child: Opacity(
                  opacity: front,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 17.w, color: AppCustomColor.kpPeekHint),
                      7.horizontalSpace,
                      AppText(
                        context.l10n.lesson.peekRecapHint,
                        style: AppStyle.text13.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppCustomColor.kpPeekHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !showingBack,
                child: Opacity(opacity: back, child: actions),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Share + Save, the design's two 38 discs.
  ///
  /// Save is absent on a GENERATED lesson, and that is the fifth catalogue side
  /// effect this reader has to hold back (next to the progress POST, the
  /// tracking context, the exit destinations and the habit lookup). Saved cards
  /// keys a bookmark by catalogue keypoint id and re-reads title/image from the
  /// `keypoints` collection on every request — a generated keypoint has no row
  /// there, so its synthesised `::user-lesson::` id resolves to nothing. The row
  /// wrote fine and then never rendered; worse, before the repository learned to
  /// drop uncastable ids it made Mongo throw and took the reader's ENTIRE Saved
  /// cards screen down with it.
  ///
  /// Sharing is untouched — it renders the card locally and asks the server
  /// nothing.
  Widget _recapActions(
    BuildContext context, {
    required String keypointTitle,
    required BaseMultiLanguage recap,
    required String recapText,
  }) {
    final l10n = context.l10n.library;
    final lessonState = context.watch<CourseLessonCubit>().state;
    final keypointId = lessonState.currentKeypointId;
    final canSave = !lessonState.selectedLesson.isImported;

    return BlocBuilder<SavedCubit, SavedState>(
      bloc: AppDI.injector.get<SavedCubit>(),
      buildWhen: (previous, current) => previous.isCardSaved(keypointId) != current.isCardSaved(keypointId),
      builder: (context, savedState) {
        final isSaved = savedState.isCardSaved(keypointId);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SavedCardActionButton.share(
              key: const Key('recap-card-share'),
              semanticsLabel: l10n.shareLabel,
              dropShadow: true,
              onTap: () => unawaited(_share(keypointTitle)),
            ),
            if (canSave) ...[
              10.horizontalSpace,
              SavedCardActionButton.bookmark(
                key: const Key('recap-card-bookmark'),
                semanticsLabel: isSaved ? l10n.unsaveCardLabel : l10n.saveCardLabel,
                isSaved: isSaved,
                dropShadow: true,
                onTap: () => unawaited(_toggleSave(recap: recap, recapText: recapText)),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Front: the design's white quote card — 290×(3:4), a giant pale quote mark
  /// behind the keypoint title, the lesson it belongs to as the uppercase
  /// source line, and the keypoint's illustration in the lower-right corner.
  Widget _quoteFront(BuildContext context, {required String keypointTitle, required String lessonTitle, required String imageUrl}) {
    return _cardShell(
      color: AppCustomColor.backgroundWhite,
      shadow: BoxShadow(color: const Color(0x1A141828), blurRadius: 34, offset: const Offset(0, 14)),
      child: Stack(
        children: [
          Positioned(
            top: 6.h,
            left: 14.w,
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: AppFont.poppins,
                fontWeight: FontWeight.w700,
                fontSize: 130.sp,
                height: 1,
                color: AppCustomColor.kpPeekQuoteMark,
              ),
            ),
          ),
          if (imageUrl.isNotEmpty)
            Positioned(
              right: 20.w,
              bottom: 20.h,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 92.w,
                height: 118.h,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            // Bottom inset keeps the text clear of the illustration corner —
            // the design reserves the card's lower strip for it.
            padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 108.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  keypointTitle,
                  maxLines: 5,
                  // Design 21/700 — the app scale has no 21, and this card is
                  // a design set piece, so it keeps the exact value.
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                    color: AppCustomColor.textPrimary,
                  ),
                ),
                11.verticalSpace,
                Container(
                  width: 28.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.kpPeekDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                if (lessonTitle.isNotEmpty) ...[
                  8.verticalSpace,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 203.w),
                    child: AppText(
                      lessonTitle.toUpperCase(),
                      maxLines: 3,
                      // Design 8.5/700, .08em tracking — exact values, see above.
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                        letterSpacing: 8.5 * 0.08,
                        color: AppCustomColor.kpPeekSource,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Back: the design's dark recap card — deep violet, the title capped at 78%
  /// width, a hairline, and the recap text scrolling under a bottom fade.
  Widget _recapBack(BuildContext context, {required String keypointTitle, required String recapText}) {
    return _cardShell(
      color: AppCustomColor.kpRecapBackSurface,
      shadow: BoxShadow(color: const Color(0x5740361B), blurRadius: 38, offset: const Offset(0, 16)),
      child: Stack(
        children: [
          Positioned(
            top: 6.h,
            right: 22.w,
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: AppFont.poppins,
                fontWeight: FontWeight.w700,
                fontSize: 64.sp,
                height: 1,
                color: AppCustomColor.textWhite.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 226.w),
                  child: AppText(
                    keypointTitle,
                    maxLines: 3,
                    // Design 17/800.
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 14.h),
                  height: 1,
                  color: AppCustomColor.textWhite.withValues(alpha: 0.24),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(right: 4.w, bottom: 24.h),
                        child: AppText(
                          recapText,
                          maxLines: 200,
                          // Design 14.5/600, lh 1.62.
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.62,
                            color: AppCustomColor.textWhite.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                      // The design's bottom fade: tells the reader there is more
                      // text without a scrollbar over a photo-free dark card.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppCustomColor.kpRecapBackSurface.withValues(alpha: 0),
                                  AppCustomColor.kpRecapBackSurface,
                                ],
                                stops: const [0, 0.88],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Both faces share the same geometry so the flip reads as one card turning.
  Widget _cardShell({required Color color, required BoxShadow shadow, required Widget child}) {
    return Container(
      width: 290.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [shadow],
      ),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(borderRadius: BorderRadius.circular(26.r), child: child),
      ),
    );
  }

  /// Continue đi thẳng sang màn hoàn thành keypoint.
  ///
  /// Trước đây ở giữa còn một bước gợi ý thói quen (`goStartHabit` trong thiết
  /// kế); bước đó mất cùng tính năng Thói quen.
  Future<void> _continue() async {
    if (_isContinuing) return;
    AppHaptic.select();
    setState(() => _isContinuing = true);
    try {
      context.read<LessonCubit>().openKeypointComplete();
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  /// Full-width Continue (design: 54 tall, pill radius) — hands the reader to
  /// the lesson-complete screen the deck used to jump to on its own.
  Widget _continueButton(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(999.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: _isContinuing ? null : _continue,
          child: Container(
            height: 54.h,
            alignment: Alignment.center,
            child: _isContinuing
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.textWhite),
                  )
                : AppText(
                    context.l10n.common.kContinue,
                    style: AppStyle.text16.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
