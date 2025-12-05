part of '../../../monetization.dart';

class PaywallBannerCarousel extends StatefulWidget {

  const PaywallBannerCarousel({super.key});

  @override
  State<PaywallBannerCarousel> createState() => _PaywallBannerCarouselState();
}

class _PaywallBannerCarouselState extends State<PaywallBannerCarousel> {
  late final CarouselController _controller;
  int _current = 0;

  List<BaseMultiLanguage> bannerDecorations = [
    BaseMultiLanguage(
      en: AppAsset.images.app.paywallBannerDecor1En.path,
      vi: AppAsset.images.app.paywallBannerDecor1Vi.path,
    ),
    BaseMultiLanguage(
      en: AppAsset.images.app.paywallBannerDecor2En.path,
      vi: AppAsset.images.app.paywallBannerDecor2Vi.path,
    ),
    BaseMultiLanguage(
      en: AppAsset.images.app.paywallBannerDecor3En.path,
      vi: AppAsset.images.app.paywallBannerDecor3Vi.path,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = CarouselController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (bannerDecorations.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 414.h,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.horizontal) return false;
              final double extent = 1.sw - (20.w * 2);
              if (extent == 0) return false;
              final int index = (notification.metrics.pixels / extent).round().clamp(0, bannerDecorations.length - 1);
              if (index != _current) {
                setState(() => _current = index);
              }
              return false;
            },
            child: CarouselView(
              controller: _controller,
              padding: EdgeInsets.zero,
              itemSnapping: true,
              itemExtent: 1.sw - (20.w * 2),
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
              children: bannerDecorations.map((banner) {
                final path = banner.text;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: path.isNotEmpty
                      ? Image.asset(
                          path,
                          fit: BoxFit.contain,
                        )
                      : Container(color: AppCustomColor.backgroundGray),
                );
              }).toList(),
            ),
          ),
        ),
        12.verticalSpace,
        _DotsIndicator(
          count: bannerDecorations.length,
          activeIndex: _current,
          activeColor: AppCustomColor.brandPrimary,
          color: AppCustomColor.greyC1,
        ),
      ],
    );
  }
}
