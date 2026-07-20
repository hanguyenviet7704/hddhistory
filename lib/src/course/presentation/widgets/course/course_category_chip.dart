part of '../../../course.dart';

class CourseCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CourseCategoryChip({
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
          color: isSelected ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected ? null : Border.all(color: AppCustomColor.borderDefault),
        ),
        child: AppText(
          label,
          style: (isSelected ? AppStyle.textBold12 : AppStyle.text12).copyWith(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.textTertiary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
