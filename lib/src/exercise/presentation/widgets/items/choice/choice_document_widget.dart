part of '../../../../exercise.dart';

class ChoiceDocumentWidget extends StatelessWidget {
  final List<ExerciseDocumentEntity> documents;

  const ChoiceDocumentWidget({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3E8EF), width: 2.w),
      ),
      child: Column(
        spacing: 16.h,
        children: documents.map((document) => ChoiceDocumentItem(document: document)).toList(),
      ),
    );
  }
}

class ChoiceDocumentItem extends StatelessWidget {
  final ExerciseDocumentEntity document;

  const ChoiceDocumentItem({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return switch (document.type) {
      ExerciseDocumentType.image => DCachedImage(url: document.data.url),
      ExerciseDocumentType.video => Container(),
      ExerciseDocumentType.audio => AudioPlayerWidget(audioUrl: document.data.url),
      ExerciseDocumentType.text => AppText(document.data.title),
    };
  }
}