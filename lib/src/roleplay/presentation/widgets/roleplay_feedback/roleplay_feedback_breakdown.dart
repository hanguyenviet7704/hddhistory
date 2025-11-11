part of '../../../roleplay.dart';

class RoleplayFeedbackBreakdownSection extends StatelessWidget {
  final List<RoleplayPointEntity> points;

  const RoleplayFeedbackBreakdownSection({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleplayFeedbackBreakdownHeader(onTapExplain: () => LessonExplainPopup.show(context)),
        12.verticalSpace,
        if (points.isEmpty) _RoleplayFeedbackBreakdownEmpty() else _RoleplayFeedbackBreakdownList(points: points),
      ],
    );
  }
}

class _RoleplayFeedbackBreakdownHeader extends StatelessWidget {
  final VoidCallback onTapExplain;

  const _RoleplayFeedbackBreakdownHeader({required this.onTapExplain});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          context.text.rolePlayResultBreakdownTitle,
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        GestureDetector(
          onTap: onTapExplain,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.text.rolePlayResultBreakdownInstruction,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              6.horizontalSpace,
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  border: Border.all(color: AppCustomColor.borderDefault),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  AppAsset.svg.common.info,
                  width: 12.w,
                  height: 12.w,
                  colorFilter: ColorFilter.mode(AppCustomColor.textSecondary, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleplayFeedbackBreakdownList extends StatelessWidget {
  final List<RoleplayPointEntity> points;

  const _RoleplayFeedbackBreakdownList({required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = AppCustomColor.gradientRoleplay;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          ...List.generate(points.length, (index) {
            final color = colors[index % colors.length];
            final tile = RoleplayFeedbackPointTile(
              point: points[index],
              accentColor: color,
            );
            final bool isLast = index == points.length - 1;
            return Column(
              children: [
                tile,
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Divider(height: 1, color: AppCustomColor.borderSecondary),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RoleplayFeedbackBreakdownEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.borderDefault),
      ),
      alignment: Alignment.center,
      child: AppText(
        context.text.emptyList,
        textAlign: TextAlign.center,
        style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
      ),
    );
  }
}

class RoleplayFeedbackPointTile extends StatelessWidget {
  final RoleplayPointEntity point;
  final Color accentColor;

  const RoleplayFeedbackPointTile({super.key, required this.point, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final String title = point.keypoint.title.text.isNotEmpty ? point.keypoint.title.text : context.text.rolePlayResultSkillset;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              title,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 2,
            ),
          ),
          12.horizontalSpace,
          RoleplayFeedbackStrengthIndicator(level: point.keypoint.strengthLevel),
        ],
      ),
    );
  }
}
