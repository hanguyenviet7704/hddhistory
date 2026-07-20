part of '../../../course.dart';

class CourseTabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CourseTabChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.backgroundBrand : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AppText(
          label,
          style: (isSelected ? AppStyle.textBold12 : AppStyle.text12).copyWith(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.textTertiary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
