part of '../../../../lesson.dart';

class DocumentWidget extends StatelessWidget {
  final List<ContentDocumentEntity> documents;
  final Map<int, String> selectedExplanationOptionKeys;
  final void Function(int contentDocumentIndex, String? optionKey)? onExplanationSelectionChanged;
  final bool asCard;

  /// When [asCard], render the wrapping card as frosted glass over a custom
  /// study background (theory keypoint design). No effect when [asCard] is false.
  final bool frosted;

  const DocumentWidget({
    super.key,
    required this.documents,
    this.selectedExplanationOptionKeys = const {},
    this.onExplanationSelectionChanged,
    this.asCard = true,
    this.frosted = false,
  });

  double topSpacing(int index) {
    if (index == 0) return 0;

    ContentDocumentType currentType = documents[index].type;
    ContentDocumentType previousType = documents[index - 1].type;

    if (currentType == ContentDocumentType.text && previousType == ContentDocumentType.title) {
      return 4.h;
    }

    return 16.h;
  }

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        documents.length,
        (index) => Padding(
          padding: EdgeInsets.only(top: topSpacing(index)),
          child: DocumentItem(
            document: documents[index],
            selectedExplanationOptionKey: selectedExplanationOptionKeys[index],
            onExplanationSelectionChanged: onExplanationSelectionChanged == null ? null : (optionKey) => onExplanationSelectionChanged!(index, optionKey),
          ),
        ),
      ),
    );

    if (!asCard) return content;
    return LessonContentCard(frosted: frosted, child: content);
  }
}
