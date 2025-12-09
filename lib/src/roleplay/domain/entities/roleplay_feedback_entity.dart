part of '../../roleplay.dart';

@freezed
abstract class RoleplayFeedbackEntity with _$RoleplayFeedbackEntity {
  const factory RoleplayFeedbackEntity({
    @Default('') String feedbackText,
    @Default(0) double timeGpt,
  }) = _RoleplayFeedbackEntity;

  factory RoleplayFeedbackEntity.fromJson(Map<String, dynamic> json) => _$RoleplayFeedbackEntityFromJson(json);
}

extension RoleplayFeedbackEntityExtension on RoleplayFeedbackEntity {
  /*
  "## Your Strongest Areas\n- Bạn đã có khả năng phân tích tình huống tốt, cho thấy sự nhạy bén trong việc nhận diện các yếu tố quan trọng. \n- Kỹ năng này giúp bạn đưa ra quyết định chính xác hơn trong các tình huống thực tế.\n\n## Where to Improve Next\n- Việc xác định mục tiêu còn yếu, cho thấy bạn chưa rõ ràng trong việc thiết lập các mục tiêu cụ thể và khả thi. \n- Hãy thực hành việc đặt ra các mục tiêu SMART (Cụ thể, Đo lường được, Có thể đạt được, Thực tế, Thời gian) để cải thiện khả năng này."
  */
  String get strongestAreas {
    if (feedbackText.isEmpty) return '';
    if (!feedbackText.contains('## Your Strongest Areas\n')) return '';
    return feedbackText.split('## Your Strongest Areas\n')[1].split('## Where to Improve Next')[0].trim();
  }

  String get whereToImproveNext {
    if (feedbackText.isEmpty) return '';
    if (!feedbackText.contains('## Where to Improve Next\n')) return '';
    return feedbackText.split('## Where to Improve Next\n')[1].trim();
  }
}