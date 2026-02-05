part of '../../../../lesson.dart';

class DocumentItem extends StatelessWidget {
  final ContentDocumentEntity document;

  const DocumentItem({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data;

    if (!document.dataAvailable) return const SizedBox.shrink();

    return switch (document.type) {
      ContentDocumentType.title || ContentDocumentType.text || ContentDocumentType.caption => DocumentContentWidget(content: data.content.text, type: document.type),
      ContentDocumentType.image || ContentDocumentType.audio => DocumentMediaWidget(url: data.url.text, type: document.type),
      ContentDocumentType.video => DocumentVideoWidget(url: data.url.text, thumbnail: data.thumbnail),
    };
  }
}
