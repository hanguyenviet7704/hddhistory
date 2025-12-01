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
  final String? entryTrackingTag;
  final bool isFromSalePopup;

  const PaywallPage({super.key, this.entryTrackingTag, this.isFromSalePopup = false});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final List<BaseMultiLanguage> bannerDecorations = [
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

  late final IapCubit _iapCubit;
  late final PaywallCubit _paywallCubit;
  late final PageController _featureController;
  late final PageController _reviewController;

  bool _hasTrackedView = false;
  bool _hasShownSuccess = false;

  @override
  void initState() {
    super.initState();
    _iapCubit = context.read<IapCubit>();
    _paywallCubit = context.read<PaywallCubit>();
    _featureController = PageController(viewportFraction: 0.88);
    _reviewController = PageController(viewportFraction: 0.9);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iapCubit.init();
      _iapCubit.loadIapProducts();

      if (widget.entryTrackingTag != null && widget.entryTrackingTag!.isNotEmpty) {
        _paywallCubit.setPaywallSource(widget.entryTrackingTag!);
      } else if (widget.isFromSalePopup) {
        _paywallCubit.setPaywallSource('sale_popup');
      }

      _trackView();
    });
  }

  @override
  void dispose() {
    _featureController.dispose();
    _reviewController.dispose();
    _iapCubit.disposeStreamSubscription();
    super.dispose();
  }

  void _trackView() {
    if (_hasTrackedView) return;
    _hasTrackedView = true;
    AppService.instance.appTrackingServiceNew.trackPaywallScrView(context);
  }

  void _onSelectProduct(String id) {
    _iapCubit.setSelectedProductId(id);
    AppService.instance.appTrackingServiceNew.trackPaywallPackageClick(context, id);
  }

  void _onPayNow(IapState state) {
    if (state.status == MonetizationStatus.loading) return;
    AppService.instance.appTrackingServiceNew.trackPaywallStartPremiumClick(context, state.selectedProductId);
    _iapCubit.purchaseProduct(type: PurchaseType.subscription);
  }

  void _onRestore() => _iapCubit.restorePurchases();

  void _onClose() {
    AppService.instance.appTrackingServiceNew.trackPaywallExitClick(context);
    context.back();
  }

  List<PaywallFeature> _benefitItems(BuildContext context) => [
    PaywallFeature(
      title: context.text.monetization.benefit1Title,
      description: context.text.monetization.benefit1Desc,
      icon: Icons.bolt_rounded,
    ),
    PaywallFeature(
      title: context.text.monetization.benefit2Title,
      description: context.text.monetization.benefit2Desc,
      icon: Icons.folder_special_rounded,
    ),
    PaywallFeature(
      title: context.text.monetization.benefit3Title,
      description: context.text.monetization.benefit3Desc,
      icon: Icons.auto_awesome,
    ),
  ];

  List<FeedbackContent> _feedbacks(BuildContext context) => [
    FeedbackContent(
      userName: 'Jenny',
      title: context.text.monetization.review1Title,
      description: context.text.monetization.review1Body,
      stars: 5,
    ),
    FeedbackContent(
      userName: 'Minh',
      title: context.text.monetization.review2Title,
      description: context.text.monetization.review2Body,
      stars: 5,
    ),
    FeedbackContent(
      userName: 'Akira',
      title: context.text.monetization.review3Title,
      description: context.text.monetization.review3Body,
      stars: 5,
    ),
  ];

  String _selectedPriceLabel(List<IapProductEntity> products, String selectedId) {
    final selected = products.where((p) => p.id == selectedId).toList();
    if (selected.isEmpty || selected.first.price.isEmpty) return '';
    return selected.first.price;
  }

  Future<void> _openAllPlans(List<IapProductEntity> products, String selectedId) async {
    if (products.isEmpty) return;

    await showMaterialModalBottomSheet(
      context: context,
      expand: false,
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return PaywallPlansSheet(
          products: products,
          selectedProductId: selectedId,
          onSelect: _onSelectProduct,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IapCubit, IapState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (!_hasShownSuccess && state.status == MonetizationStatus.success) {
          _hasShownSuccess = true;
          PaywallSuccessDialog.show(context, onExplore: () => Navigator.of(context, rootNavigator: true).pop());
        }
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundGray,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: _onClose,
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<IapCubit, IapState>(
            builder: (context, state) {
              final products = state.iapProducts;
              final selectedId = state.selectedProductId;

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => _iapCubit.loadIapProducts(),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SliverToBoxAdapter(
                          child: PaywallHeader(
                            bannerDecorations: bannerDecorations,
                            title: context.text.monetization.paywallTitle,
                            subtitle: context.text.monetization.paywallSubtitle,
                            benefits: _benefitItems(context),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: PaywallPackageList(
                            loading: state.status == MonetizationStatus.loading && products.isEmpty,
                            products: products,
                            selectedProductId: selectedId,
                            onSelect: _onSelectProduct,
                            onSeeAllPlans: () => _openAllPlans(products, selectedId),
                            emptyPlaceholder: PaywallEmptyState(
                              title: context.text.monetization.emptyProductsTitle,
                              subtitle: context.text.monetization.emptyProductsDesc,
                              onRetry: _iapCubit.loadIapProducts,
                              retryLabel: context.text.monetization.retry,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: PaywallFeatureCarousel(
                            controller: _featureController,
                            title: context.text.monetization.keyFeaturesTitle,
                            items: _benefitItems(context),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: PaywallReviewCarousel(
                            controller: _reviewController,
                            title: context.text.monetization.reviewsTitle,
                            feedbacks: _feedbacks(context),
                          ),
                        ),
                        SliverPadding(padding: EdgeInsets.only(bottom: 180.h)),
                      ],
                    ),
                  ),
                  PaywallCtaSection(
                    loading: state.status == MonetizationStatus.loading,
                    onPayNow: () => _onPayNow(state),
                    onRestore: _onRestore,
                    ctaLabel: context.text.monetization.payNowCta,
                    restoreLabel: context.text.monetization.restore,
                    priceLabel: _selectedPriceLabel(products, selectedId),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
