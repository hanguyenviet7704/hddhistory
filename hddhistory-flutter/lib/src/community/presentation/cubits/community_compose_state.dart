part of '../../community.dart';

@freezed
abstract class CommunityComposeState with _$CommunityComposeState {
  const factory CommunityComposeState({
    /// The headline. Optional — a post with only a body still reads fine, and
    /// forcing a title on someone who just wants to say one thing would turn a
    /// confession into a form.
    @Default('') String subject,
    @Default('') String body,

    /// Null means "không chọn phòng" — posting without a room is allowed.
    String? topicId,
    @Default(<String>[]) List<String> images,
    String? attachedCourseId,
    String? attachedCourseTitle,
    CommunityAttachedCardEntity? attachedCard,

    /// Hides the writer's name from readers. Moderation still sees it, and the
    /// composer says so rather than promising more than the app can give.
    @Default(false) bool isAnonymous,
    @Default(false) bool isRoomPickerOpen,
    @Default(<CommunityTopicEntity>[]) List<CommunityTopicEntity> topics,
    @Default(false) bool isSubmitting,
    @Default(false) bool isUploadingImage,
    String? errorMessage,
  }) = _CommunityComposeState;

  factory CommunityComposeState.initial() => const CommunityComposeState();
}

extension CommunityComposeStateX on CommunityComposeState {
  bool get canSubmit => body.trim().isNotEmpty && !isSubmitting && !isUploadingImage;

  /// A photo and a card each count as one. The cap is the design's: two
  /// attachments is where a post stops being a story with something added and
  /// starts being a gallery.
  static const int maxAttachments = 2;

  int get attachmentCount => images.length + (attachedCard != null ? 1 : 0) + (attachedCourseId != null ? 1 : 0);

  bool get isAttachmentFull => attachmentCount >= maxAttachments;

  /// The room this post will land in, or null for "không chọn phòng".
  CommunityTopicEntity? get selectedTopic {
    final id = topicId;
    if (id == null) return null;

    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
