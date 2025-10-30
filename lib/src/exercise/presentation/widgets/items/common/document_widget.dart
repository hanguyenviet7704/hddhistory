part of '../../../../exercise.dart';

class DocumentWidget extends StatelessWidget {
  final List<ContentDocumentEntity> documents;

  const DocumentWidget({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16.h,
        children: documents
            .map(
              (document) => DocumentItem(document: document),
            )
            .toList(),
      ),
    );
  }
}
