part of '../../../video_lesson.dart';

class VideoLessonPlayerSurface extends StatelessWidget {
  const VideoLessonPlayerSurface({
    super.key,
    required this.controller,
    required this.thumbnailUrl,
  });

  final VideoPlayerController? controller;
  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final initializedController = controller;
    final hasVideo = initializedController != null && initializedController.value.isInitialized;

    return SizedBox(
      width: double.infinity,
      child: hasVideo
          ? AspectRatio(
              aspectRatio: initializedController.value.aspectRatio,
              child: VideoPlayer(initializedController),
            )
          : AspectRatio(
              aspectRatio: 16 / 9,
              child: thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFF151B26)),
                      errorWidget: (context, url, error) => Container(color: const Color(0xFF151B26)),
                    )
                  : Container(color: const Color(0xFF151B26)),
            ),
    );
  }
}
