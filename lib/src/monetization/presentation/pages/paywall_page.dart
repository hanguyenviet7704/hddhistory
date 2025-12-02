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
        userName: 'Ava',
        title: monetizationTexts.review1Title,
        description: monetizationTexts.review1Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Minh',
        title: monetizationTexts.review2Title,
        description: monetizationTexts.review2Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Chen',
        title: monetizationTexts.review3Title,
        description: monetizationTexts.review3Body,
        stars: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final feedbackContents = _buildFeedbackContents();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PaywallPageDecoration(
              bannerDecorations: bannerDecorations,
              feedbackContents: feedbackContents,
            ),
          ],
        ),
      ),
    );
  }
}
