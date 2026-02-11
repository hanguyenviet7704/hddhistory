import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('Enum unknown fallback parsing', () {
    test('falls back for course and achievement enums', () {
      final course = CourseModel.fromJson({'status': 'future_status'});
      final roadmapLevel = RoadmapLevelModel.fromJson({'level': 'future_level'});
      final progress = CourseLevelProgressModel.fromJson({'level': 'future_level'});

      expect(course.status, CoursePublishStatus.unknown);
      expect(roadmapLevel.level, CourseLevel.unknown);
      expect(progress.level, CourseLevel.unknown);
    });

    test('falls back for lesson and question enums', () {
      final lesson = LessonModel.fromJson({
        'type': 'future_type',
        'status': 'future_status',
        'progess': 'future_progress',
      });
      final question = QuestionModel.fromJson({
        'type': 'future_type',
        'form': 'future_form',
        'level': ['weak_point', 'future_level'],
      });
      final contentDocument = ContentDocumentModel.fromJson({'type': 'future_document'});

      expect(lesson.type, LessonType.unknown);
      expect(lesson.status, LessonPublishStatus.unknown);
      expect(lesson.progess, ProcessEnum.unknown);
      expect(question.type, QuestionType.unknown);
      expect(question.form, FormDragDropType.unknown);
      expect(question.level, [KeypointLevelType.weakPoint, KeypointLevelType.unknown]);
      expect(contentDocument.type, ContentDocumentType.unknown);
    });

    test('falls back for feedback enum lists', () {
      final model = UserFeedbackIncompleteModel.fromJson({
        'reasons': ['hard_to_understand', 'future_reason'],
      });

      expect(
        model.reasons,
        [IncompleteFeedbackReason.hardToUnderstand, IncompleteFeedbackReason.unknown],
      );
    });

    test('falls back for monetization and profile enums', () {
      final product = IapProductModel.fromJson({
        'platform': 'future_store',
        'type': 'future_type',
      });
      final subscription = IapSubscriptionModel.fromJson({
        'platform': 'future_store',
        'status': 'future_status',
      });
      final verify = IapVerifyModel.fromJson({
        'platform': 'future_store',
        'status': 'future_status',
      });
      final user = UserModel.fromJson({
        'status': 'FUTURE_STATUS',
        'role': 'FUTURE_ROLE',
      });

      expect(product.platform, PaymentPlatform.unknown);
      expect(product.type, ProductType.subscriptionAutoRenew);
      expect(subscription.platform, PaymentPlatform.unknown);
      expect(subscription.status, SubscriptionStatus.unknown);
      expect(verify.platform, PaymentPlatform.unknown);
      expect(verify.status, IapPurchaseStatus.unknown);
      expect(user.status, UserAccountStatus.unknown);
      expect(user.role, UserRole.unknown);
    });

    test('falls back for progress and roleplay enums', () {
      final exercise = ExerciseResultModel.fromJson({
        'type': 'future_type',
        'form': 'future_form',
      });
      final conversation = ConversationModel.fromJson({'position': 'future_position'});
      final content = RoleplayContentModel.fromJson({'type': 'future_type'});
      final keypoint = KeypointModel.fromJson({
        'strengthLevel': 'future_strength',
        'progess': 'future_progress',
      });
      final learningItem = LearningItemModel.fromJson({'type': 'future_type'});

      expect(exercise.type, QuestionType.unknown);
      expect(exercise.form, FormDragDropType.unknown);
      expect(conversation.position, RoleplayConversationPosition.unknown);
      expect(content.type, RoleplayContentType.unknown);
      expect(keypoint.strengthLevel, StrengthLevel.unknown);
      expect(keypoint.progess, ProcessEnum.unknown);
      expect(learningItem.type, LearningItemType.unknown);
    });
  });
}
