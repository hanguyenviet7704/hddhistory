part of '../../../monetization.dart';

class FeedbackContent {
  final String userName;
  final String title;
  final String description;
  final int stars;

  FeedbackContent({
    required this.userName,
    required this.title,
    required this.description,
    required this.stars,
  });
}

class PaywallFeedbackList extends StatelessWidget {
  const PaywallFeedbackList({super.key});

  List<FeedbackContent> get _feedbacks {
    final monetizationTexts = t.monetization;

    return [
      FeedbackContent(
        userName: 'Trang',
        title: monetizationTexts.review1Title,
        description: monetizationTexts.review1Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Chi',
        title: monetizationTexts.review2Title,
        description: monetizationTexts.review2Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Duy',
        title: monetizationTexts.review3Title,
        description: monetizationTexts.review3Body,
        stars: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_feedbacks.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          children: _feedbacks.map((feedback) => _FeedbackCard(feedback: feedback)).toList(),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackContent feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 305.w,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                feedback.userName,
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textTertiary,
                ),
              ),
              const Spacer(),
              _StarRow(stars: feedback.stars),
            ],
          ),
          8.verticalSpace,
          AppText(
            feedback.title,
            maxLines: 2,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textPrimary,
            ),
          ),
          6.verticalSpace,
          AppText(
            feedback.description,
            maxLines: 6,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;

  const _StarRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 4.w),
          child: Icon(
            FontAwesomeIcons.solidStar,
            size: 14.w,
            color: isFilled ? AppCustomColor.brandPrimary : AppCustomColor.greyC1,
          ),
        );
      }),
    );
  }
}
