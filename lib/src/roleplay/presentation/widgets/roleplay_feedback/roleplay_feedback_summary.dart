part of '../../../roleplay.dart';

class RoleplayFeedbackSummarySection extends StatelessWidget {
  final List<KeypointEntity> points;

  const RoleplayFeedbackSummarySection({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final List<KeypointEntity> sorted = List<KeypointEntity>.from(points)..sort((a, b) => b.point.compareTo(a.point));
    final strengths = sorted.take(3).toList();
    final usedIds = strengths.map((point) => point.id).toSet();
    final weaknesses = sorted.reversed.where((point) => !usedIds.contains(point.id)).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.text.rolePlayResultFeedback,
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,
        _RoleplayFeedbackSummaryCard(
          title: context.text.rolePlayResultFeedbackStrength,
          items: strengths,
        ),
        12.verticalSpace,
        _RoleplayFeedbackSummaryCard(
          title: context.text.rolePlayResultFeedbackWeakness,
          items: weaknesses,
        ),
      ],
    );
  }
}

class _RoleplayFeedbackSummaryCard extends StatelessWidget {
  final String title;
  final List<KeypointEntity> items;

  const _RoleplayFeedbackSummaryCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault.op(0.7),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          12.verticalSpace,
          if (items.isEmpty)
            AppText(
              context.text.emptyList,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            )
          else ...[
            for (final item in items)
              Padding(
                padding: EdgeInsets.only(bottom: item == items.last ? 0 : 8.h),
                child: _RoleplayFeedbackSummaryRow(label: item.title.text),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoleplayFeedbackSummaryRow extends StatelessWidget {
  final String label;

  const _RoleplayFeedbackSummaryRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: AppCustomColor.textBrand.op(0.16),
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: AppText(
            label.isNotEmpty ? label : context.text.rolePlayResultSkillset,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.7,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
