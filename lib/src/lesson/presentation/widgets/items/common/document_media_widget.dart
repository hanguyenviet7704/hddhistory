part of '../../../../lesson.dart';

class DocumentMediaWidget extends StatelessWidget {
  final String url;
  final ContentDocumentType type;

  /// Theory illustrations are pinned to the design's fixed 200pt band so every
  /// card in the swipe deck has the same rhythm regardless of the artwork's
  /// aspect ratio. Question/roleplay images keep their intrinsic height.
  final DocumentProse prose;

  const DocumentMediaWidget({
    super.key,
    required this.url,
    required this.type,
    this.prose = DocumentProse.theory,
  });

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ContentDocumentType.image => CacheNetworkGraphic(
        url: url,
        width: double.infinity,
        height: prose == DocumentProse.theory ? 200.h : null,
        borderRadius: BorderRadius.circular(16.r),
        fit: BoxFit.cover,
      ),
      ContentDocumentType.audio => AudioPlayerUrlWidget(audioUrl: url),
      _ => const SizedBox.shrink(),
    };
  }
}
