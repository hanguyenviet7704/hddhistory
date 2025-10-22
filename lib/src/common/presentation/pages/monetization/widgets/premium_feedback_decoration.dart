part of '../monetization.dart';

class PremiumFeedbackDecoration extends StatefulWidget {
  const PremiumFeedbackDecoration({super.key});

  @override
  State<PremiumFeedbackDecoration> createState() => _PremiumFeedbackDecorationState();
}

class _PremiumFeedbackDecorationState extends State<PremiumFeedbackDecoration> {
  late final PageController _pageController;
  int _currentPage = 0;

  // Mock feedback data
  final List<FeedbackItem> _feedbacks = [
    FeedbackItem(
      name: 'Tracy',
      rating: 5,
      title: 'Outstanding!',
      content: 'I got tools that actually make me better every day. Totally worth it!',
    ),
    FeedbackItem(
      name: 'Michael',
      rating: 5,
      title: 'Life changing!',
      content: 'The premium features helped me improve my drawing skills in just weeks.',
    ),
    FeedbackItem(
      name: 'Sarah',
      rating: 5,
      title: 'Worth every penny',
      content: 'Unlimited energy and boosters made learning so much faster and enjoyable.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Auto-slide functionality
    Future.delayed(const Duration(milliseconds: 300), () {
      _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _feedbacks.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 225.h,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
      decoration: const BoxDecoration(
        color: Color(0x3D0A0A0A), // This is the exact color from Figma (rgba(10, 10, 10, 0.24))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _feedbacks.length,
            effect: WormEffect(
              dotColor: AppColorLight.onPrimary.op(0.3),
              activeDotColor: AppColorLight.onPrimary,
              dotHeight: 10.w,
              dotWidth: 10.w,
              spacing: 16.w,
            ),
            onDotClicked: (index) => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          // Page view with feedback items
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _feedbacks.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final feedback = _feedbacks[index];
                return _buildFeedbackItem(feedback);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(FeedbackItem feedback) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with stars and title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: Icon(
                        FontAwesomeIcons.solidStar,
                        color: AppColorLight.onPrimary,
                        size: 16.w,
                      ),
                    );
                  }),
                ),
                // Rating stars
                8.verticalSpace,

                // Title
                AppText(
                  feedback.title,
                  style: AppStyle.textBold24.copyWith(
                    color: AppColorLight.onPrimary,
                  ),
                ),
              ],
            ),

            // User name with opacity
            AppText(
              feedback.name,
              style: AppStyle.textBold18.copyWith(color: AppColorLight.onPrimary.op(0.6)),
            ),
          ],
        ),

        // Feedback content
        12.verticalSpace,
        AppText(
          feedback.content,
          style: AppStyle.text18.copyWith(color: AppColorLight.onPrimary, height: 1.33),
          textAlign: TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Model class for feedback items
class FeedbackItem {
  final String name;
  final int rating;
  final String title;
  final String content;

  FeedbackItem({
    required this.name,
    required this.rating,
    required this.title,
    required this.content,
  });
}
