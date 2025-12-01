part of '../../monetization.dart';

class PaywallHeader extends StatelessWidget {
  final List<BaseMultiLanguage> bannerDecorations;
  final String title;
  final String subtitle;
  final List<PaywallFeature> benefits;

  const PaywallHeader({
    super.key,
    required this.bannerDecorations,
    required this.title,
    required this.subtitle,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppCustomColor.gradientBackground,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 180.h,
                  child: _BannerDecoration(images: bannerDecorations),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: AppStyle.textBold24.copyWith(color: Colors.white, height: 1.3),
                    maxLines: 2,
                  ),
                  8.verticalSpace,
                  AppText(
                    subtitle,
                    style: AppStyle.text16.copyWith(color: Colors.white.op(0.95), height: 1.5),
                    maxLines: 3,
                  ),
                  16.verticalSpace,
                  Column(
                    children: benefits
                        .map(
                          (benefit) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: _BenefitRow(benefit: benefit),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final PaywallFeature benefit;

  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: Colors.white.op(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(benefit.icon, color: Colors.white, size: 16.w),
        ),
        10.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                benefit.title,
                style: AppStyle.textBold16.copyWith(color: Colors.white),
                maxLines: 2,
              ),
              4.verticalSpace,
              AppText(
                benefit.description,
                style: AppStyle.text14.copyWith(color: Colors.white.op(0.85), height: 1.4),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerDecoration extends StatelessWidget {
  final List<BaseMultiLanguage> images;

  const _BannerDecoration({required this.images});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: images
          .asMap()
          .entries
          .map(
            (entry) => Positioned(
              top: entry.key * 10.0,
              right: entry.key * 6.0,
              child: Image.asset(
                entry.value.text,
                height: 140.h,
                fit: BoxFit.contain,
              ),
            ),
          )
          .toList(),
    );
  }
}
