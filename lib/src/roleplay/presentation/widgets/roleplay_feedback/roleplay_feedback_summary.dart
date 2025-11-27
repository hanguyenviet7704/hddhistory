part of '../../../roleplay.dart';

class RoleplayFeedbackSummarySection extends StatelessWidget {
  const RoleplayFeedbackSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, RoleplayFeedbackEntity>(
      selector: (state) => state.feedback,
      builder: (context, feedback) {
        final strengths = feedback.strongestAreas.split('\n');
        final weaknesses = feedback.whereToImproveNext.split('\n');
        if (strengths.isEmpty || weaknesses.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.text.roleplay.rolePlayResultFeedback,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
            ),
            12.verticalSpace,
            _RoleplayFeedbackSummaryCard(
              title: context.text.roleplay.rolePlayResultFeedbackStrength,
              items: strengths,
            ),
            12.verticalSpace,
            _RoleplayFeedbackSummaryCard(
              title: context.text.roleplay.rolePlayResultFeedbackWeakness,
              items: weaknesses,
            ),
            32.verticalSpace,
          ],
        );
      },
    );
  }
}

class _RoleplayFeedbackSummaryCard extends StatelessWidget {
  final String title;
  final List<String> items;

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
              context.text.common.emptyList,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            )
          else ...[
            for (final item in items)
              Padding(
                padding: EdgeInsets.only(bottom: item == items.last ? 0 : 8.h),
                child: _RoleplayFeedbackSummaryRow(label: item),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          margin: EdgeInsets.only(top: 10.h),
          decoration: BoxDecoration(
            color: AppCustomColor.textBrand.op(0.16),
            shape: BoxShape.circle,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: AppText(
            label.replaceAll('- ', ''),
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.7,
            ),
            maxLines: 10,
          ),
        ),
      ],
    );
  }
}
