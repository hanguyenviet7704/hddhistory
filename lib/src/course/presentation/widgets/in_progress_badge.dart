part of '../../course.dart';

class InProgressBadge extends StatelessWidget {
  const InProgressBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: AppText(
        'In progress',
        style: AppStyle.text10.copyWith(
          fontWeight: FontWeight.w600,
          color: AppCustomColor.textWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
