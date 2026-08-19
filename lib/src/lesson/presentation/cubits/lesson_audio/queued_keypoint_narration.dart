part of '../../../lesson.dart';

/// One keypoint's merged narration handed to the player's playlist AHEAD of
/// time, so background listening carries on past the end of the keypoint the
/// app is showing (see [LessonAudioCubit.appendKeypoint]).
///
/// Everything the audio layer needs to become that keypoint the moment the
/// platform walks into its slot: the cue map to read positions with, and the
/// title/artwork the lock screen must switch to. Deliberately NOT a
/// [KeypointEntity] — the deck's copy of the keypoint arrives later (its
/// learning items are fetched after the hop), and the voice must not wait for it.
class QueuedKeypointNarration {
  const QueuedKeypointNarration({
    required this.keypointId,
    required this.title,
    required this.imageUrl,
    required this.url,
    required this.timeline,
    this.preludeSlots = 0,
  });

  /// Số slot CHUYỂN TIẾP đứng trước file merged của keypoint này trong
  /// playlist (khoảng ngắt + chime, và clip "Tiếp theo: <tên>" nếu có).
  /// [LessonAudioCubit._onSlotChanged] phải tiêu hết số slot này rồi mới
  /// adopt — mỗi entry không còn là đúng một slot nữa, và quên đếm prelude là
  /// FIFO lệch: cue map của keypoint sau bị gán cho đoạn chime.
  final int preludeSlots;

  final String keypointId;
  final String title;
  final String imageUrl;
  final String url;
  final MergedNarrationTimeline timeline;
}
