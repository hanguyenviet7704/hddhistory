part of '../../../roleplay.dart';

class RoleplayPageHeader extends StatelessWidget {
  final SectionEntity section;
  final bool useLightContent;

  const RoleplayPageHeader({
    super.key,
    required this.section,
    required this.useLightContent,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = useLightContent ? AppCustomColor.textWhite : AppCustomColor.textPrimary;
    final Color subtitleColor = section.transitionColor.toHexColor == Colors.transparent ? textColor.withValues(alpha: 0.7) : section.transitionColor.toHexColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleplayBackButton(
          isLight: useLightContent,
        ),
        16.verticalSpace,
        AppText(
          section.title,
          maxLines: 2,
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.3,
          ),
        ),
        if (section.transition.isNotEmpty) ...[
          12.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: useLightContent ? Colors.white.withValues(alpha: 0.12) : AppCustomColor.roleplayRightBubble,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: AppText(
              section.transition,
              style: AppStyle.text14.copyWith(
                color: subtitleColor,
                height: 1.4,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleplayBackButton extends StatelessWidget {
  final bool isLight;

  const _RoleplayBackButton({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isLight ? Colors.white.withValues(alpha: 0.15) : AppCustomColor.borderSecondary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18.w,
          color: isLight ? Colors.white : AppCustomColor.textPrimary,
        ),
      ),
    );
  }
}
