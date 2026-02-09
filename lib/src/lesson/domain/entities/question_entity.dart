part of '../../lesson.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String exerciseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage speechBubble,
    @Default(TagEntity()) TagEntity tag,
    @Default([]) List<ContentDocumentEntity> document,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<AnswerEntity> answer,
    @Default([]) List<OptionEntity> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default(0) int maxScore,
    @Default(0) int completionTime,
    @Default([]) List<ScoringCriteriaEntity> scoringCriteria,
    @Default(0) int mainQuestion,
    @Default(KeypointEntity()) KeypointEntity keypoint,
    @Default(QuestionPayloadEntity.singleChoice()) QuestionPayloadEntity typedPayload,

    @Default(ExerciseResultEntity()) ExerciseResultEntity result,
  }) = _QuestionEntity;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => _$QuestionEntityFromJson(json);
}

enum QuestionTypeEnum {
  @JsonValue('single_choice')
  singleChoice,
  @JsonValue('multiple_choice')
  multipleChoice,
  @JsonValue('drag_and_drop')
  dragAndDrop,
  @JsonValue('arrange_the_sequence')
  arrangeTheSequence,
  @JsonValue('cues_placement')
  cuesPlacement,
  @JsonValue('stress_placement')
  stressPlacement,
  @JsonValue('speaking')
  speaking,
}

extension QuestionEntityExtension on QuestionEntity {
  String get explanationText => explanation.text;

  bool get hasResult {
    if (result.multipleAnswer.isNotEmpty || result.dragDropAnswer.isNotEmpty) return true;
    if (result.singleAnswer.id != 0 || result.singleAnswer.labelText.isNotEmpty) return true;
    if (result.recordAnswer.record.isNotEmpty || result.recordAnswer.review.isNotEmpty) return true;
    return result.exerciseId.isNotEmpty;
  }

  bool get isCompleted => false;

  String get questionText {
    if (document.isEmpty) return 'No question text';
    return document.first.data.content.text;
  }

  String get keypointId {
    if (keypoint.id.isNotEmpty) return keypoint.id;
    LearningItemEntity currentLearningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
    if (currentLearningItem.keypointId.isNotEmpty) return currentLearningItem.keypointId;
    return '';
  }

  bool get hasExplanation => explanationText.isNotEmpty;
}
