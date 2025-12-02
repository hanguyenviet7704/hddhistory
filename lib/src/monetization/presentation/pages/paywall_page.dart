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

  @override
  void initState() {
    super.initState();
    final iapCubit = context.read<IapCubit>();
    iapCubit.init();
    iapCubit.loadIapProducts();
  }

  @override
  void dispose() {
    context.read<IapCubit>().disposeStreamSubscription();
    super.dispose();
  }

  List<FeedbackContent> _feedbackContents(BuildContext context) => [
    FeedbackContent(
      userName: 'Amelia',
      title: context.text.monetization.review1Title,
      description: context.text.monetization.review1Body,
      stars: 5,
    ),
    FeedbackContent(
      userName: 'Liam',
      title: context.text.monetization.review2Title,
      description: context.text.monetization.review2Body,
      stars: 5,
    ),
    FeedbackContent(
      userName: 'Sofia',
      title: context.text.monetization.review3Title,
      description: context.text.monetization.review3Body,
      stars: 5,
    ),
  ];

  List<PaywallBenefitItem> _benefits(BuildContext context) => [
    PaywallBenefitItem(title: context.text.monetization.benefit1Title, description: context.text.monetization.benefit1Desc),
    PaywallBenefitItem(title: context.text.monetization.benefit2Title, description: context.text.monetization.benefit2Desc),
    PaywallBenefitItem(title: context.text.monetization.benefit3Title, description: context.text.monetization.benefit3Desc),
  ];

  IapProductEntity? _selectedProduct(IapState state) {
    if (state.iapProducts.isEmpty) return null;
    return state.iapProducts.firstWhere(
      (p) => p.id == state.selectedProductId,
      orElse: () => state.iapProducts.first,
    );
  }

  Future<void> _openAllPlans(BuildContext context, IapState iapState) async {
    await showPaywallPlanBottomSheet(
      context,
      products: iapState.iapProducts,
      selectedProductId: iapState.selectedProductId,
      onSelect: (id) => context.read<IapCubit>().setSelectedProductId(id),
      onPurchase: () {
        Navigator.of(context).maybePop();
        _purchase();
      },
    );
  }

  void _purchase() => context.read<IapCubit>().purchaseProduct();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<IapCubit, IapState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == MonetizationStatus.success) {
              context.read<PaywallCubit>().showPurchaseSuccess();
            }
          },
        ),
        BlocListener<PaywallCubit, PaywallState>(
          listenWhen: (previous, current) => previous.isShowAllPlans != current.isShowAllPlans || previous.isShowPurchaseSuccess != current.isShowPurchaseSuccess,
          listener: (context, state) async {
            if (state.isShowAllPlans) {
              final iapState = context.read<IapCubit>().state;
              if (iapState.iapProducts.isNotEmpty) {
                await _openAllPlans(context, iapState);
              }
              context.read<PaywallCubit>().hideAllPlans();
            }

            if (state.isShowPurchaseSuccess) {
              await showPaywallSuccessDialog(
                context,
                onCta: () => context.backUntil(RoutePath.home),
              );
              context.read<PaywallCubit>().hidePurchaseSuccess();
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundGray,
        body: SafeArea(
          child: BlocBuilder<IapCubit, IapState>(
            builder: (context, iapState) {
              final selectedProduct = _selectedProduct(iapState);

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaywallHeader(
                          title: context.text.monetization.paywallTitle,
                          subtitle: context.text.monetization.paywallSubtitle,
                          onClose: () => context.back(),
                        ),
                        20.verticalSpace,
                        PaywallBannerCarousel(banners: bannerDecorations),
                        20.verticalSpace,
                        PaywallBenefitSection(
                          title: context.text.monetization.keyFeaturesTitle,
                          benefits: _benefits(context),
                        ),
                        24.verticalSpace,
                        _PlanSection(
                          state: iapState,
                          selectedProduct: selectedProduct,
                          onSelect: (id) => context.read<IapCubit>().setSelectedProductId(id),
                          onSeeAll: () => context.read<PaywallCubit>().showAllPlans(),
                          onPurchase: _purchase,
                          onRestore: () => context.read<IapCubit>().restorePurchases(),
                        ),
                        24.verticalSpace,
                        PaywallFeedbackSection(
                          title: context.text.monetization.reviewsTitle,
                          feedbacks: _feedbackContents(context),
                        ),
                        16.verticalSpace,
                      ],
                    ),
                  ),
                  if (iapState.status == MonetizationStatus.loading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.05),
                        child: Center(
                          child: CircularProgressIndicator(color: AppCustomColor.brandPrimary),
                        ),
                      ),
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

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.state,
    required this.selectedProduct,
    required this.onSelect,
    required this.onSeeAll,
    required this.onPurchase,
    required this.onRestore,
  });

  final IapState state;
  final IapProductEntity? selectedProduct;
  final ValueChanged<String> onSelect;
  final VoidCallback onSeeAll;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (state.status == MonetizationStatus.failure) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorLight.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppCustomColor.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.text.monetization.emptyProductsTitle,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
            ),
            6.verticalSpace,
            AppText(
              context.text.monetization.emptyProductsDesc,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            ),
            12.verticalSpace,
            AppButton.secondary(
              onPressed: () => context.read<IapCubit>().loadIapProducts(),
              child: AppText(
                context.text.monetization.retry,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (state.iapProducts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.text.monetization.loadingPlans,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          12.verticalSpace,
          LinearProgressIndicator(minHeight: 6.h, color: AppCustomColor.brandPrimary, backgroundColor: AppCustomColor.borderSecondary),
        ],
      );
    }

    final products = state.iapProducts.take(2).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorLight.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.borderSecondary),
        boxShadow: [
          BoxShadow(color: AppCustomColor.black0D.op(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                context.text.monetization.seeAllPlans,
                style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: AppText(
                  context.text.monetization.seeAllPlans,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          ...products
              .map(
                (product) => Padding(
                  padding: EdgeInsets.only(bottom: product == products.last ? 0 : 10.h),
                  child: PaywallPlanCard(
                    product: product,
                    isSelected: product.id == state.selectedProductId,
                    isMostPopular: product == products.first,
                    onTap: () => onSelect(product.id),
                  ),
                ),
              )
              .toList(),
          16.verticalSpace,
          AppButton.primary(
            fullWidthBtn: true,
            onPressed: onPurchase,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: AppText(
              selectedProduct != null ? '${context.text.monetization.payNowCta} • ${selectedProduct!.price}' : context.text.monetization.payNowCta,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textWhite),
            ),
          ),
          12.verticalSpace,
          AppButton.secondary(
            fullWidthBtn: true,
            onPressed: onRestore,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: AppText(
              context.text.monetization.restore,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
