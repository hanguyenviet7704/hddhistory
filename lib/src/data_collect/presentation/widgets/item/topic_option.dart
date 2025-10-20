part of '../../../data_collect.dart';

class TopicOption extends StatelessWidget {
  final OnboardOptionEntity value;
  final bool isSelected;
  final Function(OnboardOptionEntity?) onChanged;

  const TopicOption({
    super.key,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        // height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
          border: Border.all(
            color: isSelected
                ? const Color(0xFF554FF0) // Brand/Primary
                : const Color(0xFFE3E8EF), // Border/Default
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DCachedImage(url: value.icon, width: 24.w, height: 24.h),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    value.label.text,
                    style: AppStyle.text16.copyWith(
                      color: isSelected
                          ? const Color(0xFF0D121C) // content/primary
                          : const Color(0xFF7F8EA4), // Text/Tertiary
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                  ),
                  2.verticalSpace,
                  AppText(
                    value.label.text,
                    style: AppStyle.text12.copyWith(
                      color: isSelected
                          ? const Color(0xFF364152) // content/primary
                          : const Color(0xFF7F8DA4), // Text/Tertiary
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            8.horizontalSpace,
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: const Color(0xFF554FF0), // Brand/Primary
                size: 28.sp,
              ),
          ],
        ),
      ),
    );
  }
}
