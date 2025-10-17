part of '../../../data_collect.dart';

class GenderOption extends StatelessWidget {
  final OnboardOptionEntity value;
  final OnboardOptionEntity groupValue;
  final Function(OnboardOptionEntity?) onChanged;

  const GenderOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), // Brand/Primary or Border/Default
            width: 2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppText(value.icon, style: AppStyle.text24),
                16.horizontalSpace,
                AppText(
                  value.label.text,
                  style: AppStyle.text16.copyWith(
                    color: isSelected
                        ? const Color(0xFF0D121C) // content/primary
                        : const Color(0xFF7F8EA4), // Text/Tertiary
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            CustomRadio(
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }
}
