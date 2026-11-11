part of '../../../roleplay.dart';

class RoleplayFeedbackBreakdownSection extends StatelessWidget {
  const RoleplayFeedbackBreakdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleplayFeedbackBreakdownHeader(),
        12.verticalSpace,
        BlocSelector<RoleplayPointCubit, RoleplayPointState, List<KeypointEntity>>(
          selector: (state) => state.points,
          builder: (context, points) {
            if (points.isEmpty) return _RoleplayFeedbackBreakdownEmpty();
            return _RoleplayFeedbackBreakdownList(points: points);
          },
        ),
      ],
    );
  }
}

class _RoleplayFeedbackBreakdownHeader extends StatelessWidget {
  const _RoleplayFeedbackBreakdownHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          context.l10n.roleplay.rolePlayResultBreakdownTitle,
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        if (kDebugMode)
          GestureDetector(
            onTap: () {
              AppHaptic.select();
              LessonExplainPopup.show(context, showPoint: true);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  context.l10n.lesson.lessonLessonKeypointInstruction,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textQuaternary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                8.horizontalSpace,
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppCustomColor.textQuaternary,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppText(
                    'i',
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textQuaternary,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
        context.l10n.common.emptyList,
        textAlign: TextAlign.center,
        style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
      ),
    );
  }
}

class _RoleplayFeedbackBreakdownList extends StatelessWidget {
  final List<KeypointEntity> points;

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
            color: AppCustomColor.borderDefault.op(0.5),
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

class RoleplayFeedbackPointTile extends StatelessWidget {
  final KeypointEntity point;
  final Color accentColor;

  const RoleplayFeedbackPointTile({super.key, required this.point, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final String title = point.title.text.isNotEmpty ? point.title.text : context.l10n.roleplay.rolePlayResultCategory;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
                2.verticalSpace,
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${point.point}',
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' / 100',
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textQuaternary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          12.horizontalSpace,
          RoleplayFeedbackStrengthIndicator(level: point.strengthLevel),
        ],
      ),
    );
  }
}
