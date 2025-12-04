part of '../../../monetization.dart';

@lazySingleton
class IapCubit extends Cubit<IapState> with CubitUseCaseHandlerMixin<IapState> {
  final IMonetizationRepository _iapRepository;
  final IIapService _iapService;
  final ITrackingService _trackingService;
  final GetPackagesUsecase _getPackagesUsecase;
  final PurchaseUsecase _purchaseUsecase;
  final RestoreUsecase _restoreUsecase;
  final VerifyUsecase _verifyUsecase;

  IapCubit(
    this._iapRepository,
    this._iapService,
    this._trackingService,
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
    this._verifyUsecase,
  ) : super(IapState.initial());

  StreamSubscription<PurchaseDetails>? _purchaseDetailSubscription;

  void setSelectedProductId(String productId) {
    emit(state.copyWith(selectedProductId: productId));
    // purchaseProduct();
  }

  Future<void> init() async {
    _subscribeToPurchaseUpdates();
  }

  void disposeStreamSubscription() {
    _purchaseDetailSubscription?.cancel();
    _purchaseDetailSubscription = null;
  }

  void loadIapProducts() async {
    await runUseCase<List<IapProductEntity>>(
      usecase: () => _getPackagesUsecase.call(GetPackagesParams(platform: PaymentPlatform.fromDevicePlatform)),
      onSuccess: (products) {
        if (products.isEmpty) return;
        if (products.isEmpty) return;
        String largestProductPriceId = products.reduce((a, b) => a.rawPrice > b.rawPrice ? a : b).id;
        emit(state.copyWith(iapProducts: products, selectedProductId: largestProductPriceId));
      },
      onFailure: (error) => emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString())),
    );
  }

  Future<void> purchaseProduct() async {
    emit(state.copyWith(status: MonetizationStatus.loading));
    await runUseCase<IapVerifyEntity>(
      usecase: () => _purchaseUsecase.call(PurchaseParams(productId: state.selectedProduct.productId, type: state.selectedProduct.type)),
      onSuccess: (verify) {},
      onFailure: (error) => _onPurchaseFailure(),
    );
  }

  Future<void> restorePurchases() async {
    await runUseCase<IapVerifyEntity>(
      usecase: _restoreUsecase.call,
      onSuccess: (verify) => emit(state.copyWith(status: MonetizationStatus.success)),
      onFailure: (error) => emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString())),
    );
  }

  Future<void> _subscribeToPurchaseUpdates() async {
    if (_purchaseDetailSubscription != null) return;

    _purchaseDetailSubscription = _iapRepository.purchaseDetailStream.listen((purchaseDetail) async {
      switch (purchaseDetail.status) {
        case PurchaseStatus.pending:
          _onPurchaseFailure();

          LogDev.warning('Payment is pending');

          break;
        case PurchaseStatus.canceled:
          _onPurchaseFailure();
          LogDev.warning('Payment is canceled');

          break;
        case PurchaseStatus.error:
          _onPurchaseFailure();
          _trackingService.trackSubscriptionFailed(state.selectedProductId);
          LogDev.warning('Payment failed');

          break;
        case PurchaseStatus.purchased:
          _verifyPurchase(purchaseDetail);
          LogDev.warning('Purchase verification done');
          break;

        case PurchaseStatus.restored:
          _verifyPurchase(purchaseDetail);
          LogDev.warning('Purchase restored');
          break;
      }
    });
  }

  void _verifyPurchase(PurchaseDetails purchaseDetail) async {
    late VerifyParams params;

    if (Platform.isIOS) {
      // final verificationData = await _iapService.refreshIOSVerificationData();
      params = VerifyParams(
        platform: PaymentPlatform.apple,
        productId: purchaseDetail.productID,
        packageName: 'com.eup.meup',
        // storeTransactionId: verificationData?.serverVerificationData ?? '',
        storeTransactionId: purchaseDetail.purchaseID ?? '',
      );
    } else {
      final verificationData = purchaseDetail.verificationData;
      params = VerifyParams(
        platform: PaymentPlatform.google,
        productId: purchaseDetail.productID,
        packageName: 'com.eup.meup',
        storeTransactionId: verificationData.serverVerificationData,
      );
    }

    runUseCase<IapVerifyEntity>(
      usecase: () => _verifyUsecase.call(params),
      onSuccess: (verify) => _onPurchaseSuccess(purchaseDetail),
      onFailure: (error) => emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString())),
    );
  }

  void _onPurchaseSuccess(PurchaseDetails purchaseDetail) {
    // AppConfig.instance.context?.read<UserCubit>().getMyProfiles();
    _iapService.completePurchase(purchaseDetail);
    
    emit(state.copyWith(status: MonetizationStatus.success));
    AppConfig.instance.context?.backUntil(RoutePath.home);

    _trackingService.trackSubscriptionCompleted(state.selectedProductId);

    Future.delayed(const Duration(seconds: 1), () async {
      AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(AppConfig.instance.context!, true);
      DMessage.showMessage(
        message: AppConfig.instance.context?.text.monetization.paymentSuccessToast ?? '',
        type: MessageType.success,
      );
      // await PremiumPopupProductionUnlock.show(AppConfig.instance.context!);
    });
  }

  void _onPurchaseFailure({String error = ''}) {
    emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString()));
    _trackingService.trackPaywallStorePopupDismiss(AppConfig.instance.context!, state.selectedProductId);
    DMessage.showMessage(
      message: error.isEmpty ? AppConfig.instance.context?.text.monetization.paymentFailToast ?? '' : error,
      type: MessageType.error,
    );
  }

  @override
  Future<void> close() {
    _purchaseDetailSubscription?.cancel();
    return super.close();
  }
}
