part of '../../learning_import.dart';

/// Peek and snap values lifted from the catalogue deck so this feels like the
/// same deck. Copied rather than imported: they are private to
/// `keypoint_card_shell.dart`.
///
/// Only these three -- the catalogue shell drives paging from raw pointer events
/// because a card's inner scroller and the deck swipe have to share the gesture.
/// Here the cards scroll vertically inside a vertical PageView too, but with no
/// gates to enforce there is nothing to intercept, so PageView's own physics do.
const double _kPeekViewportFraction = 0.937;
const Duration _kSnapDuration = Duration(milliseconds: 420);
const Cubic _kSnapCurve = Cubic(0.22, 0.7, 0.25, 1);

/// Reads a generated lesson as a deck of swipeable cards — one card per section.
///
/// Deliberately NOT [KeypointCardShell], which is this design already built:
/// that widget is driven by `KeypointCardCubit`, which needs `LessonCubit`,
/// `TheoryCubit` and `LessonAudioCubit`, rebuilds its cards from lesson state,
/// and carries narration gating and the in-lesson paywall. Driving it from a
/// generated lesson would mean fabricating a lesson. The habit quiz screen faced
/// the same choice and made the same call — see its docblock.
///
/// Simpler than the catalogue deck in one way that matters: there are no gates.
/// A summary has no questions, so all ten cards are open from the start and the
/// reader can swipe both ways freely.
class LessonDeckPage extends StatefulWidget {
  const LessonDeckPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<LessonDeckPage> createState() => _LessonDeckPageState();
}

class _LessonDeckPageState extends State<LessonDeckPage> {
  PageController? _pageController;
  int _cardIndex = 0;

  /// Set while the deck is moving itself, so the resulting page callback is not
  /// mistaken for the reader swiping and does not seek the audio back.
  bool _selfDriven = false;

  @override
  void initState() {
    super.initState();
    context.read<UserLessonCubit>().openLesson(widget.lessonId);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int startIndex) {
    if (_pageController != null) return;

    _cardIndex = startIndex;
    _pageController = PageController(
      initialPage: startIndex,
      viewportFraction: _kPeekViewportFraction,
    );
  }

  void _onCardChanged(int index) {
    setState(() => _cardIndex = index);
    context.read<UserLessonCubit>().saveProgress(
      lessonId: widget.lessonId,
      sectionIndex: index,
    );

    // Only when the READER moved. The voice moving the deck must not seek the
    // voice, or the two chase each other.
    if (_selfDriven) {
      _selfDriven = false;
      return;
    }
    final audio = context.read<UserLessonAudioCubit>();
    if (audio.state.hasStarted) unawaited(audio.seekToCard(index));
  }

  /// The deck follows the voice.
  void _followVoice(int voiceCardIndex) {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    if (voiceCardIndex == _cardIndex) return;

    _selfDriven = true;
    controller.animateToPage(
      voiceCardIndex,
      duration: _kSnapDuration,
      curve: _kSnapCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: ThemedBackground(
        child: SafeBody(
          child: BlocBuilder<UserLessonCubit, UserLessonState>(
            builder: (context, state) {
              final lesson = state.selected;

              if (state.isLoading || lesson == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (lesson.sections.isEmpty) {
                return Center(
                  child: AppText(
                    context.l10n.learningImport.errorGeneric,
                    style: AppStyle.text14,
                  ),
                );
              }

              _ensureController(
                lesson.stopAtSectionIndex.clamp(0, lesson.sections.length - 1),
              );

              return MultiBlocListener(
                listeners: [
                  // Attach the player once the lesson (and therefore its cue
                  // map) is in hand.
                  BlocListener<UserLessonCubit, UserLessonState>(
                    listenWhen: (previous, current) =>
                        previous.selected?.id != current.selected?.id,
                    listener: (context, state) {
                      final loaded = state.selected;
                      if (loaded != null) {
                        unawaited(
                          context.read<UserLessonAudioCubit>().attach(loaded),
                        );
                      }
                    },
                  ),
                  BlocListener<UserLessonAudioCubit, UserLessonAudioState>(
                    listenWhen: (previous, current) =>
                        previous.voiceCardIndex != current.voiceCardIndex,
                    listener: (context, audioState) =>
                        _followVoice(audioState.voiceCardIndex),
                  ),
                ],
                child: Column(
                  children: [
                    _DeckHeader(
                      title: lesson.title,
                      cardCount: lesson.sections.length,
                      cardIndex: _cardIndex,
                      canListen: lesson.canListen,
                      isDubbing: lesson.isDubbing,
                      onJump: (index) {
                        _selfDriven = false;
                        _pageController?.animateToPage(
                          index,
                          duration: _kSnapDuration,
                          curve: _kSnapCurve,
                        );
                      },
                    ),
                    Expanded(
                      child: PageView.builder(
                        key: const ValueKey('user-lesson-deck'),
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: lesson.sections.length,
                        onPageChanged: _onCardChanged,
                        itemBuilder: (context, index) => _DeckCard(
                          section: lesson.sections[index],
                          isLast: index == lesson.sections.length - 1,
                          onFinish: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Close button, title, progress pips, and the narration pill.
class _DeckHeader extends StatelessWidget {
  const _DeckHeader({
    required this.title,
    required this.cardCount,
    required this.cardIndex,
    required this.canListen,
    required this.isDubbing,
    required this.onJump,
  });

  final String title;
  final int cardCount;
  final int cardIndex;
  final bool canListen;
  final bool isDubbing;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final ink = studyThemeOnBg(context, AppCustomColor.textPrimary);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 12.w, 4.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close_rounded, size: 22.w, color: ink),
              ),
              Expanded(
                child: AppText(
                  title,
                  maxLines: 1,
                  style: AppStyle.textBold16.copyWith(color: ink),
                ),
              ),
              if (canListen)
                const _NarrationPill()
              else if (isDubbing)
                // Honest about the wait rather than showing a control that
                // would do nothing: narration is still being generated.
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        _ProgressPips(count: cardCount, current: cardIndex, onTap: onJump),
        10.verticalSpace,
      ],
    );
  }
}

/// One pip per card; the current one is wider. Same idea as the catalogue's
/// `KeypointProgressPipBar`, minus the reveal bound — every card is reachable.
class _ProgressPips extends StatelessWidget {
  const _ProgressPips({
    required this.count,
    required this.current,
    required this.onTap,
  });

  final int count;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: Row(
        children: List.generate(count, (index) {
          final isCurrent = index == current;

          return Expanded(
            flex: isCurrent ? 5 : 1,
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: isCurrent ? 7.h : 5.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: index <= current
                      ? AppCustomColor.brandPrimary
                      : AppCustomColor.borderDefault,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// One section as one card. Long sections scroll INSIDE the card — the same
/// arrangement the catalogue deck uses, and the reason ten cards can hold a
/// whole lesson without becoming a hundred.
class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.section,
    required this.isLast,
    required this.onFinish,
  });

  final LessonSectionEntity section;
  final bool isLast;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: ThemedGlassCard(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        radius: 22.r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      section.title,
                      maxLines: 3,
                      style: AppStyle.textBold16,
                    ),
                    12.verticalSpace,
                    for (final block in section.blocks)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: AppText(
                          block.text,
                          // Prose: never truncate. AppText defaults to 10 lines,
                          // which would silently clip most paragraphs here.
                          maxLines: 1000,
                          overflow: TextOverflow.visible,
                          style: block.type == LessonBlockTypeEntity.heading
                              ? AppStyle.textBold16
                              : AppStyle.text16.copyWith(height: 1.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isLast) ...[
              12.verticalSpace,
              DButton(
                text: context.l10n.common.kContinue,
                backgroundColor: AppCustomColor.brandPrimary,
                size: Size(double.infinity, 50.h),
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textWhite,
                ),
                onPressed: onFinish,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Collapsed headphone circle when silent, expanded pill while playing — the
/// shape the catalogue reader uses. Copied rather than reused: the original is
/// declared inside `keypoint_card_shell.dart` and reads `KeypointCardCubit`.
class _NarrationPill extends StatelessWidget {
  const _NarrationPill();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserLessonAudioCubit, UserLessonAudioState>(
      builder: (context, state) {
        final cubit = context.read<UserLessonAudioCubit>();

        if (state.isLoading) {
          return SizedBox(
            width: 34.w,
            height: 34.w,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Semantics(
          button: true,
          label: context.l10n.learningImport.listenLabel,
          child: GestureDetector(
            key: const Key('user-lesson-narration-toggle'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptic.select();
              unawaited(cubit.toggle());
            },
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: state.isPlaying
                    ? AppCustomColor.brandPrimary
                    : AppCustomColor.brandPrimary50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.headphones_rounded,
                size: 18.w,
                color: state.isPlaying
                    ? AppCustomColor.textWhite
                    : AppCustomColor.brandPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
