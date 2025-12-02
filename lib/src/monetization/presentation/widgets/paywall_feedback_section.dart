part of '../../monetization.dart';

class PaywallFeedbackSection extends StatelessWidget {
  const PaywallFeedbackSection({super.key, required this.title, required this.feedbacks});

  final String title;
  final List<FeedbackContent> feedbacks;

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: feedbacks.map((item) => _PaywallFeedbackCard(content: item)).toList(),
          ),
        ),
      ],
    );
  }
}

class _PaywallFeedbackCard extends StatelessWidget {
  const _PaywallFeedbackCard({required this.content});

  final FeedbackContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorLight.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.black0D.op(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  content.userName,
                  style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
                  maxLines: 1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  content.stars,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 2.w),
                    child: Icon(
                      Icons.star,
                      color: AppCustomColor.yellowFF,
                      size: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            content.title,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            maxLines: 2,
          ),
          6.verticalSpace,
          AppText(
            content.description,
            maxLines: 4,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
          ),
        ],
      ),
    );
  }
}
