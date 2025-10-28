part of '../../../../exercise.dart';

class ArrangeSequenceAnswerCard extends StatelessWidget {
  final String text;
  final int index;

  const ArrangeSequenceAnswerCard({
    super.key,
    required this.text,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE3E8EF),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ReorderableDragStartListener(
          index: index,
          child: Row(
            children: [
              Icon(
                Icons.menu,
                color: const Color(0xFF7F8EA4),
                size: 24.sp,
              ),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  text,
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xFF364152),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
