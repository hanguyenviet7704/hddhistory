part of '../../monetization.dart';

class PaywallPageDecoration extends StatefulWidget {
  final List<BaseMultiLanguage> bannerDecorations;
  final List<FeedbackContent> feedbackContents;

  const PaywallPageDecoration({super.key, required this.bannerDecorations, required this.feedbackContents});

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  late final PageController _bannerController;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppCustomColor.backgroundBrand,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopBar(),
            16.verticalSpace,
            _buildHeroTitle(),
            12.verticalSpace,
            _buildSubtitle(),
            24.verticalSpace,
            _buildBannerCarousel(),
            24.verticalSpace,
            _buildFeedbackSection(),
            28.verticalSpace,
            _buildRestorePurchase(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 24.w),
        _PremiumPill(),
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Icon(
            Icons.close,
            color: AppCustomColor.textTertiary,
            size: 24.w,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return AppText(
      t.monetization.paywallHeroTitle,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: AppStyle.text32.copyWith(
        fontWeight: FontWeight.w700,
        color: AppCustomColor.textBrand,
        height: 1.25,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AppText(
      t.monetization.paywallHeroSubtitle,
      textAlign: TextAlign.center,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textBrand.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    if (widget.bannerDecorations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 414.h,
          child: PageView.builder(
            controller: _bannerController,
            clipBehavior: Clip.none,
            itemCount: widget.bannerDecorations.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final bannerPath = widget.bannerDecorations[index].text;

              return Padding(
                padding: EdgeInsets.only(right: index == widget.bannerDecorations.length - 1 ? 0 : 12.w),
                child: AnimatedBuilder(
                  animation: _bannerController,
                  builder: (context, child) {
                    double scale = 1;
                    if (_bannerController.positions.isNotEmpty && _bannerController.hasClients) {
                      final page = _bannerController.page ?? _bannerController.initialPage.toDouble();
                      scale = 1 - (page - index).abs() * 0.05;
                      scale = scale.clamp(0.9, 1.0);
                    }

                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: bannerPath.isNotEmpty
                          ? Image.asset(
                              bannerPath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: AppCustomColor.backgroundGray,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        12.verticalSpace,
        SmoothPageIndicator(
          controller: _bannerController,
          count: widget.bannerDecorations.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8.h,
            dotWidth: 8.w,
            spacing: 6.w,
            expansionFactor: 3,
            activeDotColor: AppCustomColor.brandPrimary,
            dotColor: AppCustomColor.greyC1,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    if (widget.feedbackContents.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 192.h,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _FeedbackCard(
            feedback: widget.feedbackContents[index],
          );
        },
        separatorBuilder: (_, __) => 12.horizontalSpace,
        itemCount: widget.feedbackContents.length,
      ),
    );
  }

  Widget _buildRestorePurchase() {
    return AppText(
      t.monetization.restore,
      textAlign: TextAlign.center,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textBrand.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
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
            maxLines: 4,
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
            Icons.star_rounded,
            size: 14.w,
            color: isFilled ? AppCustomColor.brandPrimary : AppCustomColor.greyC1,
          ),
        );
      }),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppCustomColor.backgroundWhite),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
      child: AppText(
        t.monetization.premiumBadge,
        style: AppStyle.text12.copyWith(
          fontWeight: FontWeight.w600,
          color: AppCustomColor.textWhite,
        ),
      ),
    );
  }
}
