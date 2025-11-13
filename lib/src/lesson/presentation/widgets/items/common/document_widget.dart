part of '../../../../lesson.dart';

class DocumentWidget extends StatelessWidget {
  final List<ContentDocumentEntity> documents;

  const DocumentWidget({super.key, required this.documents});

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
        children: documents.map((document) => DocumentItem(document: document)).toList(),
      ),
    );
  }
}
