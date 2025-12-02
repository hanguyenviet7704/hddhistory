part of '../../monetization.dart';

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

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
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

  List<FeedbackContent> _buildFeedbackContents() {
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
    final feedbackContents = _buildFeedbackContents();

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrand,
      body: SafeArea(
        child: PaywallPageDecoration(
          bannerDecorations: bannerDecorations,
          feedbackContents: feedbackContents,
        ),
      ),
    );
  }
}
