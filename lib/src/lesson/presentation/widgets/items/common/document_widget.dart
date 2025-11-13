part of '../../../../lesson.dart';

class DocumentWidget extends StatelessWidget {
  final List<ContentDocumentEntity> documents;

  const DocumentWidget({super.key, required this.documents});

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
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: ShapeDecoration(
        color: AppColorLight.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2.w,
            color: const Color(0xFFE3E8EF),
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          documents.length,
          (index) => Padding(
            padding: EdgeInsets.only(top: topSpacing(index)),
            child: DocumentItem(document: documents[index]),
          ),
        ),
      ),
    );
  }
}
