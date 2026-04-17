part of '../../../../lesson.dart';

class DocumentWidget extends StatelessWidget {
  final List<ContentDocumentEntity> documents;
  final Map<int, String> selectedExplanationOptionKeys;
  final void Function(int contentDocumentIndex, String? optionKey)? onExplanationSelectionChanged;

  const DocumentWidget({
    super.key,
    required this.documents,
    this.selectedExplanationOptionKeys = const {},
    this.onExplanationSelectionChanged,
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

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      decoration: ShapeDecoration(
        color: AppColorLight.surface,
        shape: RoundedRectangleBorder(
          // side: BorderSide(
          //   width: 2.w,
          //   color: const Color(0xFFE3E8EF),
          // ),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Column(
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
      ),
    );
  }
}
