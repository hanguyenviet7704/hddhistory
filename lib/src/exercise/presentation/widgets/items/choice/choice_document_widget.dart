part of '../../../../exercise.dart';

class ChoiceDocumentWidget extends StatelessWidget {
  final List<ExerciseDocumentEntity> documents;

  const ChoiceDocumentWidget({super.key, required this.documents});

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
              (document) => ChoiceDocumentItem(document: document),
            )
            .toList(),
      ),
    );
  }
}
