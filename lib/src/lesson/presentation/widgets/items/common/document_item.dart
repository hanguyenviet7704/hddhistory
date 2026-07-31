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
      ContentDocumentType.image || ContentDocumentType.audio => DocumentMediaWidget(url: data.url.text, type: document.type, prose: prose),
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
