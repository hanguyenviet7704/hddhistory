part of '../../../../lesson.dart';

class DocumentItem extends StatelessWidget {
  final ContentDocumentEntity document;
  final String? selectedExplanationOptionKey;
  final ValueChanged<String?>? onExplanationSelectionChanged;

  /// Which typographic role this document plays — reading copy on a theory card
  /// versus the question stem on an exercise card. See [DocumentProse].
  final DocumentProse prose;

  const DocumentItem({
    super.key,
    required this.document,
    this.selectedExplanationOptionKey,
    this.onExplanationSelectionChanged,
    this.prose = DocumentProse.theory,
  });

  @override
  Widget build(BuildContext context) {
    final data = document.data;

    if (!document.dataAvailable) return const SizedBox.shrink();

    return switch (document.type) {
      ContentDocumentType.title || ContentDocumentType.text || ContentDocumentType.caption => DocumentContentWidget(content: data.content.text, type: document.type, prose: prose),
      // An image block carries its photo credit in `content` — the field the
      // other block types use for copy. CC BY / CC BY-SA oblige us to name the
      // author and licence next to the picture, so it travels with the image
      // rather than as a separate block: a `caption` block renders as a short
      // label chip, which is the wrong shape for a credit line.
      ContentDocumentType.image || ContentDocumentType.audio => DocumentMediaWidget(url: data.url.text, type: document.type, prose: prose, credit: data.content.text),
      ContentDocumentType.video => DocumentVideoWidget(url: data.url.text, thumbnail: data.thumbnail),
      ContentDocumentType.explanation => DocumentExplanationWidget(
        key: ObjectKey(document),
        title: data.content.text,
        options: data.options,
        selectedOptionKey: selectedExplanationOptionKey,
        onSelectionChanged: onExplanationSelectionChanged,
      ),
      ContentDocumentType.unknown => const SizedBox.shrink(),
    };
  }
}
