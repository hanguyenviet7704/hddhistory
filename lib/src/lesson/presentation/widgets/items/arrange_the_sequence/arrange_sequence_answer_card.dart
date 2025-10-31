part of '../../../../lesson.dart';

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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                Icons.menu_rounded,
                color: const Color(0xFFCDD5DF),
                size: 24.sp,
              ),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  text,
                  maxLines: 10,
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
