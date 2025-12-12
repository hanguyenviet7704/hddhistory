part of '../../../../lesson.dart';

class DocumentMediaWidget extends StatelessWidget {
  final String url;
  final ContentDocumentType type;
  const DocumentMediaWidget({super.key, required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ContentDocumentType.image => CacheNetworkGraphic(
        url: url,
        width: double.infinity,
        borderRadius: BorderRadius.circular(16.r),
        fit: BoxFit.cover,
      ),
      ContentDocumentType.audio => AudioPlayerWidget(audioUrl: url),
      _ => const SizedBox.shrink(),
    };
  }
}
