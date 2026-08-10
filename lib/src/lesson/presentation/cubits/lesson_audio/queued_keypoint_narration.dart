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
  });

  final String keypointId;
  final String title;
  final String imageUrl;
  final String url;
  final MergedNarrationTimeline timeline;
}
