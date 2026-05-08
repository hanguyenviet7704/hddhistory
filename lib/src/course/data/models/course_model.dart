part of '../../course.dart';

@freezed
abstract class CourseModel with _$CourseModel {
  const factory CourseModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
    @Default([]) @JsonKey(unknownEnumValue: OnboardingSymptom.unknown) List<OnboardingSymptom> onboardingSymptoms,
    @JsonKey(unknownEnumValue: CoursePublishStatus.unknown) @Default(CoursePublishStatus.published) CoursePublishStatus status,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) => _$CourseModelFromJson(json);
}

enum CoursePublishStatus {
  @JsonValue('published')
  published,
  @JsonValue('draft')
  draft,
  @JsonValue('inactive')
  inactive,
  @JsonValue('unknown')
  unknown,
}

enum OnboardingPath {
  @JsonValue('FEEL_BETTER')
  feelBetter,
  @JsonValue('THINK_BETTER')
  thinkBetter,
  @JsonValue('WORK_BETTER')
  workBetter,
  @JsonValue('CONNECT_BETTER')
  connectBetter,
  @JsonValue('LEARN_BETTER')
  learnBetter,
  @JsonValue('EXPLORE_BETTER')
  exploreBetter,
  ;

  String get title => switch (this) {
    feelBetter => l10n.onboarding.onboardingIntroduceMyFeelings,
    thinkBetter => l10n.onboarding.onboardingIntroduceMyThoughts,
    workBetter => l10n.onboarding.onboardingIntroduceBusyAllDay,
    connectBetter => l10n.onboarding.onboardingIntroduceTalkToMany,
    learnBetter => l10n.onboarding.onboardingIntroduceLearnFades,
    exploreBetter => l10n.onboarding.onboardingIntroduceNothingNew,
  };

  String get shortTitle => switch (this) {
    feelBetter => 'Feel',
    thinkBetter => 'Think',
    workBetter => 'Work',
    connectBetter => 'Connect',
    learnBetter => 'Learn',
    exploreBetter => 'Explore',
  };

  String get image => switch (this) {
    feelBetter => AppAsset.icons.app.icHeart.path,
    thinkBetter => AppAsset.icons.app.icCompass.path,
    workBetter => AppAsset.icons.app.icDirectHit.path,
    connectBetter => AppAsset.icons.app.icSpeechBallon.path,
    learnBetter => AppAsset.icons.app.icBook.path,
    exploreBetter => AppAsset.icons.app.icWorldMap.path,
  };

  String get imageDisable => switch (this) {
    feelBetter => AppAsset.icons.app.icHeartDisable.path,
    thinkBetter => AppAsset.icons.app.icCompassDisable.path,
    workBetter => AppAsset.icons.app.icDirectHitDisable.path,
    connectBetter => AppAsset.icons.app.icSpeechBallonDisable.path,
    learnBetter => AppAsset.icons.app.icBookDisable.path,
    exploreBetter => AppAsset.icons.app.icWorldMapDisable.path,
  };

  List<OnboardingSymptom> get symptoms => switch (this) {
    feelBetter => [
      OnboardingSymptom.motivationDisappears,
      OnboardingSymptom.lifeFeelsOverwhelming,
      OnboardingSymptom.endlessScrollingFeelsEmpty,
    ],
    thinkBetter => [
      OnboardingSymptom.overthinking,
      OnboardingSymptom.tryingToDoTooMuch,
      OnboardingSymptom.rushedDecisions,
    ],
    workBetter => [
      OnboardingSymptom.difficultyBuildingHabits,
      OnboardingSymptom.timeSlipsAway,
      OnboardingSymptom.strugglingToBreakBadHabits,
    ],
    connectBetter => [
      OnboardingSymptom.anxietyAroundHardConversations,
      OnboardingSymptom.wantToListenMoreDeeply,
      OnboardingSymptom.regretSayingThingsInEmotion,
    ],
    learnBetter => [
      OnboardingSymptom.learningDoesNotStick,
      OnboardingSymptom.forgettingAfterStudying,
      OnboardingSymptom.losingTrainOfThought,
    ],
    exploreBetter => [
      OnboardingSymptom.curiousAboutBody,
      OnboardingSymptom.loveLearningFromGreatMinds,
      OnboardingSymptom.amazedByHumanBody,
    ],
  };
}

enum OnboardingSymptom {
  @JsonValue('MOTIVATION_DISAPPEARS')
  motivationDisappears,
  @JsonValue('LIFE_FEELS_OVERWHELMING')
  lifeFeelsOverwhelming,
  @JsonValue('ENDLESS_SCROLLING_FEELS_EMPTY')
  endlessScrollingFeelsEmpty,

  @JsonValue('OVERTHINKING')
  overthinking,
  @JsonValue('TRYING_TO_DO_TOO_MUCH')
  tryingToDoTooMuch,
  @JsonValue('RUSHED_DECISIONS')
  rushedDecisions,

  @JsonValue('DIFFICULTY_BUILDING_HABITS')
  difficultyBuildingHabits,
  @JsonValue('TIME_SLIPS_AWAY')
  timeSlipsAway,
  @JsonValue('STRUGGLING_TO_BREAK_BAD_HABITS')
  strugglingToBreakBadHabits,

  @JsonValue('ANXIETY_AROUND_HARD_CONVERSATIONS')
  anxietyAroundHardConversations,
  @JsonValue('WANT_TO_LISTEN_MORE_DEEPLY')
  wantToListenMoreDeeply,
  @JsonValue('REGRET_SAYING_THINGS_IN_EMOTION')
  regretSayingThingsInEmotion,

  @JsonValue('LEARNING_DOES_NOT_STICK')
  learningDoesNotStick,
  @JsonValue('FORGETTING_AFTER_STUDYING')
  forgettingAfterStudying,
  @JsonValue('LOSING_TRAIN_OF_THOUGHT')
  losingTrainOfThought,

  @JsonValue('CURIOUS_ABOUT_BODY')
  curiousAboutBody,
  @JsonValue('LOVE_LEARNING_FROM_GREAT_MINDS')
  loveLearningFromGreatMinds,
  @JsonValue('AMAZED_BY_HUMAN_BODY')
  amazedByHumanBody,

  @JsonValue('UNKNOWN')
  unknown,
}

extension CourseModelExtension on CourseModel {
  CourseEntity toEntity() => CourseEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    skillsetId: skillsetId,
    numberOfLesson: numberOfLesson,
    onboardingSymptoms: onboardingSymptoms,
    status: status,
  );
}
