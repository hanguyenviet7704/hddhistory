part of '../../../setting.dart';

class ChangeLanguageOptionTile extends StatelessWidget {
  const ChangeLanguageOptionTile({
    super.key,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final AppLocale locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary;
    final Color textColor = isSelected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary;
    final List<BoxShadow>? shadows = isSelected
        ? [
            BoxShadow(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ]
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  locale.label,
                  style: AppStyle.text16.copyWith(
                    color: textColor,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 48.w,
                height: 32.h,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.r)),
                clipBehavior: Clip.antiAlias,
                child: SvgPicture.asset(
                  locale.flagCircle,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
