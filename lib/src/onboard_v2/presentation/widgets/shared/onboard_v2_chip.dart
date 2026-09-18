part of '../../../onboard_v2.dart';

/// Chip bo tròn dùng ở S5 (vấn đề, `Wrap` nhiều dòng) và S8 (3 khung giờ
/// nhanh). Viền + nền đổi theo trạng thái chọn; chữ tối đa 2 dòng vì nhãn gói
/// ở tiếng Việt/CJK có thể dài.
class OnboardV2Chip extends StatelessWidget {
  const OnboardV2Chip({super.key, required this.label, required this.selected, required this.onTap, this.compact = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Cỡ nhỏ của S8 (13,5px, đệm 9-14). Mặc định là cỡ S5 (14,5px, đệm 11-16).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(99.r);
    return InkWell(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      borderRadius: borderRadius,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14.w : 16.w, vertical: compact ? 9.h : 11.h),
        decoration: BoxDecoration(
          color: selected ? AppCustomColor.brandPrimary.op(0.08) : AppCustomColor.backgroundWhite,
          borderRadius: borderRadius,
          border: Border.all(color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary, width: 1.5.w),
        ),
        child: AppText(
          label,
          maxLines: 2,
          style: AppStyle.text14.copyWith(
            fontSize: compact ? 13.5.sp : 14.5.sp,
            color: selected ? AppCustomColor.brandPrimary : AppCustomColor.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
