part of '../../video_lesson.dart';

String videoLessonNormalizedShareThumbnailUrl(String rawUrl) {
  return rawUrl.trim();
}

bool videoLessonShouldPreloadShareThumbnail({
  required VideoLessonState previous,
  required VideoLessonState current,
}) {
  return videoLessonShouldPreloadShareThumbnailForStateChange(
    previous,
    current,
  );
}

bool videoLessonShouldPreloadShareThumbnailForStateChange(
  VideoLessonState previous,
  VideoLessonState current,
) {
  final currentThumbnailUrl = videoLessonNormalizedShareThumbnailUrl(
    current.lesson.video.thumbnail,
  );

  if (!current.isReady || currentThumbnailUrl.isEmpty) {
    return false;
  }

  if (!previous.isReady) {
    return true;
  }

  final previousThumbnailUrl = videoLessonNormalizedShareThumbnailUrl(
    previous.lesson.video.thumbnail,
  );
  return previousThumbnailUrl != currentThumbnailUrl;
}
