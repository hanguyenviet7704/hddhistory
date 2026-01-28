part of '../../feedback.dart';

class FeedbackReasonChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FeedbackReasonChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppCustomColor.brandPrimary : Colors.transparent;
    final backgroundColor = isSelected ? AppCustomColor.backgroundWhite : AppCustomColor.borderDefault;
    final textColor = isSelected ? AppCustomColor.textBrand : AppCustomColor.textTertiary;
    final textWeight = isSelected ? FontWeight.w600 : FontWeight.w400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: borderColor, width: isSelected ? 2.w : 0),
        ),
        child: AppText(
          label,
          textAlign: TextAlign.center,
          style: AppStyle.text12.copyWith(
            color: textColor,
            fontWeight: textWeight,
            height: 1.75,
          ),
        ),
      ),
    );
  }
}
