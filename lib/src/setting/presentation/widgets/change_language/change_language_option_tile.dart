part of '../../../setting.dart';

class ChangeLanguageOptionTile extends StatelessWidget {
  const ChangeLanguageOptionTile({
    super.key,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final LocaleType locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary;
    final Color textColor = isSelected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppCustomColor.brandPrimary.withValues(alpha: .08),
                      blurRadius: 24,
                      offset: Offset(0, 12.h),
                    ),
                  ]
                : null,
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
