part of '../../monetization.dart';

class PaywallReviewCarousel extends StatefulWidget {
  final PageController controller;
  final String title;
  final List<FeedbackContent> feedbacks;

  const PaywallReviewCarousel({
    super.key,
    required this.controller,
    required this.title,
    required this.feedbacks,
  });

  @override
  State<PaywallReviewCarousel> createState() => _PaywallReviewCarouselState();
}

class _PaywallReviewCarouselState extends State<PaywallReviewCarousel> {
  @override
  Widget build(BuildContext context) {
    if (widget.feedbacks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppText(
              widget.title,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
            ),
          ),
          12.verticalSpace,
          SizedBox(
            height: 200.h,
            child: PageView.builder(
              controller: widget.controller,
              itemCount: widget.feedbacks.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = widget.feedbacks[index];
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 20.w : 10.w, right: index == widget.feedbacks.length - 1 ? 20.w : 10.w),
                  child: _ReviewCard(item: item),
                );
              },
            ),
          ),
          10.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SmoothPageIndicator(
              controller: widget.controller,
              count: widget.feedbacks.length,
              effect: ExpandingDotsEffect(
                dotHeight: 6.h,
                dotWidth: 6.h,
                activeDotColor: AppCustomColor.brandPrimary,
                dotColor: AppCustomColor.borderSecondary,
                expansionFactor: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedbackContent item;

  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
        boxShadow: [
          BoxShadow(color: Colors.black.op(0.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StarRow(stars: item.stars),
                const Spacer(),
                AppText(
                  item.userName,
                  style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
                ),
              ],
            ),
            10.verticalSpace,
            AppText(
              item.title,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
              maxLines: 2,
            ),
            6.verticalSpace,
            AppText(
              item.description,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
              maxLines: 4,
            ),
          ],
        ),
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
      children: List.generate(5, (index) {
        final filled = index < stars;
        return Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Icon(
            Icons.star_rounded,
            size: 16.w,
            color: filled ? AppCustomColor.yellowFF : AppCustomColor.borderSecondary,
          ),
        );
      }),
    );
  }
}
