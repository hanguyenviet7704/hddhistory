part of '../../monetization.dart';

class PaywallBannerCarousel extends StatefulWidget {
  final List<BaseMultiLanguage> banners;

  const PaywallBannerCarousel({super.key, required this.banners});

  @override
  State<PaywallBannerCarousel> createState() => _PaywallBannerCarouselState();
}

class _PaywallBannerCarouselState extends State<PaywallBannerCarousel> {
  late final CarouselController _controller;
  int _current = 0;

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
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 414.h,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.horizontal) return false;
              final double extent = 1.sw - (20.w * 2);
              if (extent == 0) return false;
              final int index = (notification.metrics.pixels / extent).round().clamp(0, widget.banners.length - 1);
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
              children: widget.banners.map((banner) {
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
          count: widget.banners.length,
          activeIndex: _current,
          activeColor: AppCustomColor.brandPrimary,
          color: AppCustomColor.greyC1,
        ),
      ],
    );
  }
}
