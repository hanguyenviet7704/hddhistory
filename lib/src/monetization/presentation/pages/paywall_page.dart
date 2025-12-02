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

  List<FeedbackContent> feedbackContents = [];

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
