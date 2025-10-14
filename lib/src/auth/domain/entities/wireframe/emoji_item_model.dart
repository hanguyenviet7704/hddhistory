part of '../entities.dart';

enum EmojiItemType {
  veryHard,
  hard,
  normal,
  interesting,
  veryInteresting,
}

class EmojiItemModel {
  final String iconDefault;
  final String iconActive;
  final String? title;
  final EmojiItemType type;

  const EmojiItemModel({
    required this.iconDefault,
    required this.iconActive,
    this.title,
    required this.type,
  });
}

enum FeedbackImpressAbout {
  clearGuidance('clear_guidance'),
  engagingLesson('engaging_lesson'),
  entertaining('entertaining'),
  creativeInspiration('creative_inspiration'),
  improveSkills('improve_skills'),
  shareArtwork('share_artwork'),
  getFeedback('get_feedback'),
  usefulForBeginners('useful_for_beginners');

  final String value;

  const FeedbackImpressAbout(this.value);

  static String getText(String value, BuildContext context) {
    switch (value) {
      case 'clear_guidance':
        return context.text.roadmapFeedbackAfterPayPositiveTag1;
      case 'engaging_lesson':
        return context.text.roadmapFeedbackAfterPayPositiveTag2;
      case 'entertaining':
        return context.text.roadmapFeedbackAfterPayPositiveTag3;
      case 'creative_inspiration':
        return context.text.roadmapFeedbackAfterPayPositiveTag4;
      case 'improve_skills':
        return context.text.roadmapFeedbackAfterPayPositiveTag5;
      case 'share_artwork':
        return context.text.roadmapFeedbackAfterPayPositiveTag6;
      case 'get_feedback':
        return context.text.roadmapFeedbackAfterPayPositiveTag7;
      case 'useful_for_beginners':
        return context.text.roadmapFeedbackAfterPayPositiveTag8;
      default:
        return context.text.roadmapFeedbackAfterPayPositiveTag1;
    }
  }
}

enum FeedbackImprove {
  lessonQuality('lesson_quality'),
  easeOfUse('ease_of_use'),
  learningPath('learning_path'),
  visualDesign('design_visual'),
  levelsTooHard('levels_too_hard'),
  confusingTutorials('confusing_tutorials'),
  hardToStayFocused('hard_to_stay_focused'),
  limitedBrushTypes('limited_brush_types');

  final String value;

  const FeedbackImprove(this.value);

  static String getText(String value, BuildContext context) {
    switch (value) {
      case 'lesson_content':
        return context.text.roadmapFeedbackAfterPayNegativeTag1;
      case 'ease_of_use':
        return context.text.roadmapFeedbackAfterPayNegativeTag2;
      case 'learning_path':
        return context.text.roadmapFeedbackAfterPayNegativeTag3;
      case 'design_visual':
        return context.text.roadmapFeedbackAfterPayNegativeTag4;
      case 'levels_too_hard':
        return context.text.roadmapFeedbackAfterPayNegativeTag5;
      case 'confusing_tutorials':
        return context.text.roadmapFeedbackAfterPayNegativeTag6;
      case 'hard_to_stay_focused':
        return context.text.roadmapFeedbackAfterPayNegativeTag7;
      case 'limited_brush_types':
        return context.text.roadmapFeedbackAfterPayNegativeTag8;
      default:
        return context.text.roadmapFeedbackAfterPayNegativeTag1;
    }
  }
}

extension FeedbackImpressAboutExtension on FeedbackImpressAbout {
  String displayText(BuildContext context) => FeedbackImpressAbout.getText(value, context);
}

extension FeedbackImproveExtension on FeedbackImprove {
  String displayText(BuildContext context) => FeedbackImprove.getText(value, context);
}
