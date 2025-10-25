part of '../../../../exercise.dart';

class ChoiceDocumentWidget extends StatelessWidget {
  final List<ExerciseDocumentEntity> documents;

  const ChoiceDocumentWidget({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color shadowColor = const Color(0xFF0D121C).withAlpha((0.04 * 255).round());

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE3E8EF), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < documents.length; i++) ...[
            ChoiceDocumentItem(document: documents[i]),
            if (i != documents.length - 1) ...[
              SizedBox(height: 16.h),
              Container(
                height: 1.h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFFE3E8EF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ],
        ],
      ),
    );
  }
}
