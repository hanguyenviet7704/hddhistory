part of '../../../../lesson.dart';

/// The reader's working answer for ONE question in a practice quiz deck —
/// the habit quiz and the keypoint practice quiz both own a list of these.
///
/// The lesson flow keeps this in four separate cubits (`ChoiceCubit`,
/// `DragAndDropCubit`, `ArrangeTheSequenceCubit`, …), each a `@lazySingleton`
/// holding exactly one live question and writing `user_progress` for the lesson
/// it belongs to. A practice deck needs N answers alive at once (the design lets
/// you swipe back to any earlier question) and must not write lesson progress at
/// all, so the state lives here instead — one instance per card, owned by the
/// deck.
///
/// Grading mirrors those cubits exactly so a practice quiz marks an answer the
/// same way the lesson would:
///  - choice: the selected set equals the correct set
///  - text gap: every slot holds its slot's correct answer
///  - arrange: the current order equals the answer order, position by position
class QuizCardAnswer {
  QuizCardAnswer(this.question) {
    // Word bank / draggable rows start as the authored option order, same as
    // `DragAndDropCubit.setQuestion` / `ArrangeTheSequenceCubit.setQuestion`.
    availableWords = questionRuntimeOptions(question)
        .map((option) => option.labelText)
        .where((text) => text.isNotEmpty)
        .toList();
    arrangeItems = List<OptionEntity>.from(questionRuntimeOptions(question));
  }

  final QuestionEntity question;

  bool hasChecked = false;
  bool isCorrect = false;

  /// Choice questions: indices into [choiceOptions].
  final Set<int> selected = {};

  /// Text gap: slot index → the word dropped in it, and what is left in the bank.
  final Map<int, String> placedWords = {};
  late List<String> availableWords;

  /// Arrange the sequence: the rows in their current order.
  late List<OptionEntity> arrangeItems;

  QuestionTypeEnum get type => question.type;

  bool get isChoice => type == QuestionTypeEnum.singleChoice || type == QuestionTypeEnum.multipleChoice;
  bool get isMultiChoice => type == QuestionTypeEnum.multipleChoice;
  bool get isTextGap => type == QuestionTypeEnum.dragAndDrop;
  bool get isArrange => type == QuestionTypeEnum.arrangeTheSequence;

  /// True for the four types the design's quiz deck covers. Anything else
  /// (speaking, cues/stress placement) is filtered out before a deck is built —
  /// those need a microphone or a lesson-only renderer.
  bool get isPlayable => isChoice || isTextGap || isArrange;

  /// Same test without building an answer — for filtering a question list
  /// before a deck exists.
  static bool isPlayableQuestion(QuestionEntity question) => switch (question.type) {
    QuestionTypeEnum.singleChoice ||
    QuestionTypeEnum.multipleChoice ||
    QuestionTypeEnum.dragAndDrop ||
    QuestionTypeEnum.arrangeTheSequence => true,
    _ => false,
  };

  /// The keypoint's playable exercise questions, straight from the loaded
  /// lesson items — what the practice quiz deals as cards. The same filter the
  /// server's habit-practice derivation applies: `type: exercise` items with
  /// questions, in authored order.
  static List<QuestionEntity> practiceQuestionsOf(LessonState lessonState) => lessonState.pageData.items
      .where((item) => item.type == LearningItemType.exercise)
      .expand((item) => item.mainQuestions)
      .where(isPlayableQuestion)
      .toList();

  List<QuestionChoiceOptionEntity> get choiceOptions => switch (question.typedPayload) {
    QuestionSingleChoicePayloadEntity(:final options) => options,
    QuestionMultipleChoicePayloadEntity(:final options) => options,
    _ => const [],
  };

  List<AnswerEntity> get answers => questionRuntimeAnswers(question);

  String get targetArea => questionRuntimeTargetArea(question).text;

  /// Slots in the gap sentence: one per answer, but never more than the sentence
  /// actually has blanks for (`___`). Copied from `DragAndDropStateExtension`.
  int get dropZoneCount {
    final answerCount = answers.length;
    if (answerCount == 0) return 0;
    final blankCount = targetArea.split('___').length - 1;
    if (blankCount <= 0) return answerCount;
    return math.min(answerCount, blankCount);
  }

  /// Whether there is enough of an answer for grading to mean anything — what
  /// keeps the Check pill inert rather than merely a no-op.
  bool get canCheck {
    if (hasChecked) return false;
    if (isChoice) return selected.isNotEmpty;
    if (isTextGap) {
      final required = dropZoneCount;
      if (required == 0) return false;
      for (var i = 0; i < required; i++) {
        final word = placedWords[i];
        if (word == null || word.isEmpty) return false;
      }
      return true;
    }
    if (isArrange) return arrangeItems.isNotEmpty;
    return false;
  }

  //* --- Choice ---

  void toggleChoice(int index) {
    if (hasChecked) return;
    if (isMultiChoice) {
      selected.contains(index) ? selected.remove(index) : selected.add(index);
    } else {
      selected
        ..clear()
        ..add(index);
    }
  }

  AnswerState choiceStateFor(int index) {
    final isSelected = selected.contains(index);
    if (!hasChecked) return isSelected ? AnswerState.selected : AnswerState.normal;
    final options = choiceOptions;
    final correct = index < options.length && options[index].isCorrect;
    if (isSelected && correct) return AnswerState.correct;
    if (isSelected && !correct) return AnswerState.incorrect;
    if (correct) return AnswerState.correctNotSelected;
    return AnswerState.disabled;
  }

  //* --- Text gap ---

  void placeWord(int index, String word, int? fromIndex) {
    if (hasChecked) return;
    if (fromIndex != null) {
      placedWords.remove(fromIndex);
    } else {
      availableWords.remove(word);
    }
    placedWords[index] = word;
  }

  void removeWord(int index) {
    if (hasChecked) return;
    final word = placedWords.remove(index);
    if (word != null && word.isNotEmpty && !availableWords.contains(word)) {
      availableWords.add(word);
    }
  }

  SlotState slotStateFor(int index) {
    if (!hasChecked) return SlotState.normal;
    final placed = placedWords[index];
    if (placed == null || placed.isEmpty) return SlotState.normal;
    if (index >= answers.length) return SlotState.incorrect;
    return placed == answers[index].correctAnswer.text ? SlotState.correct : SlotState.incorrect;
  }

  //* --- Arrange ---

  /// Takes [newIndex] ALREADY adjusted for the removed row — i.e. straight from
  /// `ReorderableListView.onReorderItem`, whose whole point over the deprecated
  /// `onReorder` is that it does that adjustment. Doing `newIndex -= 1` here as
  /// well would drop a row dragged downward one position short.
  void reorder(int oldIndex, int newIndex) {
    if (hasChecked) return;
    final item = arrangeItems.removeAt(oldIndex);
    arrangeItems.insert(newIndex, item);
  }

  List<String> get _correctOrder => answers.map((answer) => answer.correctAnswer.text).toList();

  ArrangeAnswerState arrangeStateFor(int index) {
    if (!hasChecked) return ArrangeAnswerState.normal;
    final correct = _correctOrder;
    if (index >= arrangeItems.length || index >= correct.length) return ArrangeAnswerState.incorrect;
    return arrangeItems[index].labelText == correct[index] ? ArrangeAnswerState.correct : ArrangeAnswerState.incorrect;
  }

  /// 1-based position the row at [index] belongs at — the design shows the number
  /// on a misplaced row instead of a bare cross.
  int? correctPositionFor(int index) {
    if (index < 0 || index >= arrangeItems.length) return null;
    final position = _correctOrder.indexOf(arrangeItems[index].labelText);
    return position < 0 ? null : position + 1;
  }

  //* --- Grading ---

  void check() {
    if (hasChecked) return;
    hasChecked = true;
    isCorrect = switch (type) {
      QuestionTypeEnum.singleChoice || QuestionTypeEnum.multipleChoice => _isChoiceCorrect,
      QuestionTypeEnum.dragAndDrop => _isTextGapCorrect,
      QuestionTypeEnum.arrangeTheSequence => _isArrangeCorrect,
      _ => false,
    };
  }

  /// Exact set match, so missing one of several correct options is wrong — the
  /// same rule the lesson's multiple choice uses.
  bool get _isChoiceCorrect {
    final options = choiceOptions;
    final correctIndices = <int>{};
    for (var i = 0; i < options.length; i++) {
      if (options[i].isCorrect) correctIndices.add(i);
    }
    if (correctIndices.isEmpty) return false;
    return selected.length == correctIndices.length && selected.containsAll(correctIndices);
  }

  bool get _isTextGapCorrect {
    final list = answers;
    if (list.isEmpty) return false;
    for (var i = 0; i < list.length; i++) {
      if (placedWords[i] != list[i].correctAnswer.text) return false;
    }
    return true;
  }

  bool get _isArrangeCorrect {
    final correct = _correctOrder;
    final current = arrangeItems.map((item) => item.labelText).toList();
    if (correct.length != current.length) return false;
    for (var i = 0; i < correct.length; i++) {
      if (correct[i] != current[i]) return false;
    }
    return true;
  }

  /// The API's `ExerciseType`, or null when this question type has no value
  /// there. `arrange_the_sequence` deliberately has none: the attempt DTO
  /// validates `type` with `@IsEnum(ExerciseType)`, and that enum only covers
  /// `single_choice`, `multiple_choice`, `single_choice_no_correct_answer`,
  /// `drag_drop` and `record` — sending the arrange string would 400 the whole
  /// submission. It is dropped rather than mislabelled as `drag_drop`, so the
  /// stored row is honest; `exerciseId` still identifies the question.
  String? get _apiExerciseType => switch (type) {
    QuestionTypeEnum.singleChoice => 'single_choice',
    QuestionTypeEnum.multipleChoice => 'multiple_choice',
    QuestionTypeEnum.dragAndDrop => 'drag_drop',
    _ => null,
  };

  /// One `ExerciseResult` row for the attempt — the same shape lesson progress
  /// stores, so a practice answer reads the same as a lesson answer. Carries the
  /// reader's ACTUAL answer, not just pass/fail.
  Map<String, dynamic> toResult() {
    final apiType = _apiExerciseType;
    final result = <String, dynamic>{
      'exerciseId': question.id.toString(),
      if (apiType != null) 'type': apiType,
      'passed': isCorrect,
      'score': isCorrect ? 1 : 0,
    };

    if (isChoice) {
      final options = choiceOptions;
      final chosen = (selected.toList()..sort())
          .where((i) => i < options.length)
          .map((i) => {'value': options[i].value.toJson(), 'isCorrect': options[i].isCorrect})
          .toList();
      if (isMultiChoice) {
        result['multipleAnswer'] = chosen;
      } else if (chosen.isNotEmpty) {
        result['singleAnswer'] = chosen.first;
      }
    } else if (isTextGap) {
      // Slot order matters — index i is the word dropped in blank i.
      result['dragDropAnswer'] = [
        for (var i = 0; i < dropZoneCount; i++) {'id': i, 'text': placedWords[i] ?? ''},
      ];
    } else if (isArrange) {
      result['dragDropAnswer'] = [
        for (var i = 0; i < arrangeItems.length; i++) {'id': i, 'text': arrangeItems[i].labelText},
      ];
    }

    return result;
  }
}
