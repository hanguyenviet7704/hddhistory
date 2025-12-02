part of '../../monetization.dart';

class PaywallBannerCarousel extends StatefulWidget {
  const PaywallBannerCarousel({super.key, required this.banners});

  final List<BaseMultiLanguage> banners;

  @override
  State<PaywallBannerCarousel> createState() => _PaywallBannerCarouselState();
}

class _PaywallBannerCarouselState extends State<PaywallBannerCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: EdgeInsets.only(right: index == widget.banners.length - 1 ? 0 : 12.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    color: AppCustomColor.backgroundGray,
                    child: Image.asset(
                      banner.text,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        12.verticalSpace,
        SmoothPageIndicator(
          controller: _pageController,
          count: widget.banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6.h,
            dotWidth: 6.w,
            spacing: 6.w,
            expansionFactor: 3,
            activeDotColor: AppCustomColor.brandPrimary,
            dotColor: AppCustomColor.borderSecondary,
          ),
          onDotClicked: (index) => _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }
}
