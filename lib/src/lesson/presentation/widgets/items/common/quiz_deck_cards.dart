part of '../../../../lesson.dart';

/// Shared rendering for one question card in a vertically-swiped practice quiz
/// deck (design `_Keypoint Swipe Lab`, `mode="quiz"`). Two decks use it — the
/// habit quiz and the keypoint practice quiz — so a question renders identically
/// wherever it is practised; only submission and chrome differ per deck.
///
/// The widgets underneath are the lesson's own ([ChoiceAnswerCard],
/// [SentenceBuilder], [AnswerCardsArea], [ArrangeSequenceAnswerCard],
/// [KeypointExerciseAction], [KeypointExerciseInstruction]); only the per-card
/// answer state ([QuizCardAnswer]) is deck-local. The host owns that state and
/// rebuilds on [onChanged] — this widget is deliberately stateless so the
/// deck's PageView can rebuild cards freely without losing answers.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.answer,
    required this.reorderKeyPrefix,
    required this.onChanged,
    required this.onCheck,
  });

  final QuizCardAnswer answer;

  /// Uniquifies the reorderable rows across decks and pages — two decks on the
  /// navigator stack must never share a row key.
  final String reorderKeyPrefix;

  /// The host's setState: every answer mutation goes through it.
  final VoidCallback onChanged;

  /// Grade this card. The host decides what grading reveals.
  final VoidCallback onCheck;

  /// [QuestionEntity.questionText] falls back to the literal string
  /// 'No question text' when the document list is empty — which is a NORMAL
  /// authoring shape for gap-filling questions (the sentence lives in
  /// `targetArea`, there is no separate prompt). Rendering the fallback as a
  /// title put "No question text" above real questions; the instruction line
  /// alone is the design's header for those cards. (video_lesson and
  /// daily_warm_up filter the same magic value.)
  String get _displayQuestionText {
    final text = answer.question.questionText;
    return text == 'No question text' ? '' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question first, instruction under it — the design's order. Leading
        // with "Select the best answer" buried the actual question.
        if (_displayQuestionText.isNotEmpty)
          AppText(
            _displayQuestionText,
            maxLines: 8,
            // Design 15.5/800 — heavier and SMALLER than the 18/700 this used to
            // draw. A question is a lead-in, not a headline: at 18 it took two
            // lines where the design takes one, and pushed the options down.
            style: AppStyle.text16.copyWith(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: AppCustomColor.textPrimary,
            ),
          ),
        4.verticalSpace,
        KeypointExerciseInstruction(text: _instruction(context)),
        // Expanded, not Flexible: the design puts a `flex:1` spacer BETWEEN the
        // answer area and the action, so the pill sits at the card's BOTTOM.
        Expanded(child: SingleChildScrollView(child: _answerArea(context))),
        14.verticalSpace,
        _action(context),
      ],
    );
  }

  /// Per-type instruction line. One colour for all of them — see
  /// [KeypointExerciseInstruction].
  String _instruction(BuildContext context) {
    if (answer.isTextGap) return context.l10n.exercise.exerciseGapFillingInstruction;
    if (answer.isArrange) return context.l10n.exercise.exerciseSequenceInstruction;
    return answer.isMultiChoice ? context.l10n.exercise.exerciseSelectManyInstruction : context.l10n.exercise.exerciseSelectOneInstruction;
  }

  Widget _answerArea(BuildContext context) {
    if (answer.isTextGap) return _textGapArea(context);
    if (answer.isArrange) return _arrangeArea(context);
    return _choiceArea(context);
  }

  Widget _choiceArea(BuildContext context) {
    final options = answer.choiceOptions;
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          // Design gap between options.
          if (i > 0) 8.verticalSpace,
          ChoiceAnswerCard(
            option: OptionEntity(value: options[i].value, isCorrect: options[i].isCorrect),
            isMultiChoice: answer.isMultiChoice,
            state: answer.choiceStateFor(i),
            onTap: () {
              answer.toggleChoice(i);
              onChanged();
            },
          ),
        ],
      ],
    );
  }

  /// Text gap: the sentence with its blanks, then the word bank. Both widgets are
  /// the lesson's own — only the state they read is local.
  Widget _textGapArea(BuildContext context) {
    return IgnorePointer(
      ignoring: answer.hasChecked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SentenceBuilder(
            placedWords: answer.placedWords,
            targetArea: answer.targetArea,
            answerCount: answer.dropZoneCount,
            onSlotTapped: (index) {
              answer.removeWord(index);
              onChanged();
            },
            onWordPlaced: (index, word, fromIndex) {
              answer.placeWord(index, word, fromIndex);
              onChanged();
            },
            onWordRemoved: (index) {
              answer.removeWord(index);
              onChanged();
            },
            getSlotState: answer.slotStateFor,
          ),
          18.verticalSpace,
          AnswerCardsArea(
            pool: answer.wordPool,
            availableWords: answer.availableWords,
            onWordReturnedFromSlot: (word, fromIndex) {
              answer.removeWord(fromIndex);
              onChanged();
            },
            // Tap fills the FIRST empty gap, left to right — the reading order,
            // and the only order that needs no second gesture to say "this gap".
            // A tap with every gap already full is a no-op rather than a silent
            // overwrite of an answer the reader placed deliberately.
            onWordTapped: (word) {
              final slot = answer.firstEmptySlot;
              if (slot == null) return;
              answer.placeWord(slot, word, null);
              onChanged();
            },
          ),
        ],
      ),
    );
  }

  /// Arrange the sequence: a reorderable list of the lesson's own rows.
  ///
  /// `buildDefaultDragHandles: false` + an explicit handle per row matches the
  /// lesson, and matters more here: the deck itself is a vertical PageView, so a
  /// full-row drag would be ambiguous with a page swipe. Only the handle drags.
  Widget _arrangeArea(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: answer.arrangeItems.length,
      onReorderItem: (oldIndex, newIndex) {
        answer.reorder(oldIndex, newIndex);
        onChanged();
      },
      proxyDecorator: (child, index, animation) => child,
      itemBuilder: (context, index) {
        final item = answer.arrangeItems[index];
        return ReorderableDragStartListener(
          key: Key('$reorderKeyPrefix-${item.id}-$index'),
          index: index,
          enabled: !answer.hasChecked,
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ArrangeSequenceAnswerCard(
              text: item.labelText,
              index: index,
              state: answer.arrangeStateFor(index),
              dragEnabled: !answer.hasChecked,
              correctPosition: answer.hasChecked ? answer.correctPositionFor(index) : null,
            ),
          ),
        );
      },
    );
  }

  /// Check pill before grading, then the verdict banner — both from the lesson's
  /// [KeypointExerciseAction], so the result reads identically. After grading the
  /// design advances by SWIPE, so there is no Continue button; the swipe hint
  /// names what the swipe leads to.
  Widget _action(BuildContext context) {
    if (!answer.hasChecked) {
      return QuizActionPill(
        label: context.l10n.exercise.exerciseCheckButton,
        isEnabled: answer.canCheck,
        onPressed: onCheck,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeypointExerciseAction(
          hasChecked: true,
          isCorrect: answer.isCorrect,
          explanationText: answer.question.explanationText,
          // Gap filling is the one type whose right answer cannot be read off
          // the card: a wrong choice leaves the correct OPTION highlighted, but
          // a wrong sentence just empties its slots. The design answers that with
          // a strip above the verdict, printing the sentence with the right words
          // in it — the lesson's own reading deck has had it all along
          // (`drag_and_drop_lesson_body`); this deck was showing the verdict with
          // no answer in it.
          correctAnswer: answer.isTextGap
              ? GapFillCorrectAnswerPanel(
                  targetArea: answer.targetArea,
                  correctAnswers: answer.correctGapWords,
                )
              : null,
        ),
        12.verticalSpace,
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.l10n.exercise.exerciseSwipeNextHint,
                style: AppStyle.text13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textTertiary,
                ),
              ),
              4.horizontalSpace,
              Icon(Icons.keyboard_arrow_up_rounded, size: 18.w, color: AppCustomColor.textTertiary),
            ],
          ),
        ),
      ],
    );
  }
}

/// The deck's card surface: frosted over a custom study background, solid white
/// on the default preset — the design's `rgba(255,255,255,.62)` panel over the
/// themed wallpaper.
class QuizDeckCardSurface extends StatelessWidget {
  const QuizDeckCardSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ThemedGlassCard(
      frosted: true,
      radius: 22,
      padding: EdgeInsets.all(22.w),
      shadow: [
        BoxShadow(
          color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
      child: child,
    );
  }
}

/// The design's in-card action pill: centred, sized to its label with a 168
/// minimum, 46 tall, disabled in low-saturation brand rather than grey so it
/// still reads as the next thing to press.
///
/// Not [KeypointCheckAnswerButton]: that hardcodes the lesson's "Check answer"
/// string, and the practice decks need several labels.
class QuizActionPill extends StatelessWidget {
  const QuizActionPill({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        enabled: isEnabled,
        child: Material(
          color: isEnabled ? AppCustomColor.brandPrimary : AppCustomColor.kpCheckDisabled,
          borderRadius: BorderRadius.circular(999.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: isEnabled ? onPressed : null,
            // A Row(mainAxisSize.min), not `alignment:` — an alignment turns the
            // Container into an Align that expands to the incoming width and the
            // pill would stretch across the card.
            child: Container(
              constraints: BoxConstraints(minWidth: 168.w),
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 26.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.textWhite),
                    )
                  else
                    AppText(
                      label,
                      style: AppStyle.text16.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
