part of '../../blocs.dart';

@lazySingleton
class IAPCubit extends Cubit<IAPState> with CubitUseCaseHandlerMixin<IAPState> {
  final IIAPRepository _iapRepository;
  final IIapService _iapService;
  final ITrackingService _trackingService;
  final GetPackagesUsecase _getPackagesUsecase;
  final PurchaseUsecase _purchaseUsecase;
  final RestoreUsecase _restoreUsecase;
  final VerifyIOSUsecase _verifyIosUsecase;
  final VerifyAndroidUsecase _verifyAndroidUsecase;

  IAPCubit(
    this._iapRepository,
    this._iapService,
    this._trackingService,
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
    this._verifyIosUsecase,
    this._verifyAndroidUsecase,
  ) : super(IAPState.initial());

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
    await executeListUseCase(
      usecase: _getPackagesUsecase.call,
      onSuccess: (products) {
        if (products.data.isEmpty) return;
        if (products.data.isEmpty) return;
        String largestProductPriceId = products.data.reduce((a, b) => a.rawPrice > b.rawPrice ? a : b).id;
        emit(state.copyWith(iapProducts: products.data, selectedProductId: largestProductPriceId));
      },
      onFailure: (error) => emit(state.copyWith(error: error.toString())),
    );
  }

  Future<void> purchaseProduct({PurchaseType type = PurchaseType.subscription}) async {
    emit(state.copyWith(isLoading: true));
    await executeUseCase(
      usecase: () => _purchaseUsecase.call(PurchaseParams(productId: state.selectedProductId, type: type)),
      onSuccess: (verify) {},
      onFailure: (error) => _onPurchaseFailure(),
    );
  }

  Future<void> restorePurchases() async {
    await executeUseCase(
      usecase: () => _restoreUsecase.call(),
      onSuccess: (verify) => emit(state.copyWith(isLoading: false)),
      onFailure: (error) => emit(state.copyWith(error: error.toString(), isLoading: false)),
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
          _iapService.completePurchase(purchaseDetail);
          _onPurchaseFailure();
          LogDev.warning('Payment is canceled');

          break;
        case PurchaseStatus.error:
          _iapService.completePurchase(purchaseDetail);
          _onPurchaseFailure();
          _trackingService.trackSubscriptionFailed(state.selectedProductId);
          LogDev.warning('Payment failed');

          break;
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _iapService.completePurchase(purchaseDetail);

          if (Platform.isIOS) {
            _verifyIosPurchase(purchaseDetail);
          } else {
            _verifyAndroidPurchase(purchaseDetail);
          }

          LogDev.warning('Purchase verification done');
          break;
      }
    });
  }

  void _verifyIosPurchase(PurchaseDetails purchaseDetail) async {
    final verificationData = await _iapService.refreshIOSVerificationData();
    executeUseCase(
      usecase: () => _verifyIosUsecase.call(
        VerifyIOSParams(
          receiptData: verificationData?.serverVerificationData ?? '',
          transactionId: purchaseDetail.purchaseID ?? '',
          isSandbox: kDebugMode,
        ),
      ),
      onSuccess: (verify) => _onPurchaseSuccess(),
      onFailure: (error) => emit(state.copyWith(error: error.toString(), isLoading: false)),
    );
  }

  void _verifyAndroidPurchase(PurchaseDetails purchaseDetail) async {
    executeUseCase(
      usecase: () => _verifyAndroidUsecase.call(
        VerifyAndroidParams(
          receiptData: purchaseDetail.verificationData.serverVerificationData,
          productId: purchaseDetail.productID,
        ),
      ),
      onSuccess: (verify) => _onPurchaseSuccess(),
      onFailure: (error) => emit(state.copyWith(error: error.toString(), isLoading: false)),
    );
  }

  void _onPurchaseSuccess() {
    AppConfig.instance.context?.read<UserCubit>().getMyProfiles();
    AppConfig.instance.context?.read<PaywallCubit>().fakeInfiniteEnergy();
    emit(state.copyWith(isLoading: false));
    AppConfig.instance.context?.backUntil(RoutePath.home);
    bool isGuest = AppConfig.instance.context?.read<UserCubit>().state.isGuest ?? true;
  
    _trackingService.trackSubscriptionCompleted(state.selectedProductId);
    if (!isGuest) {
      Future.delayed(const Duration(seconds: 1), () {
        String userId = AppConfig.instance.context?.read<UserCubit>().state.user.id ?? '';
        AppConfig.instance.context?.read<PaywallCubit>().addUserPremiumId(userId);
        DMessage.showMessage(
          message: AppConfig.instance.context?.text.monetPaymentSuccessToast ?? '',
          type: MessageType.success,
        );
      });
      return;
    }

    Future.delayed(const Duration(seconds: 1), () async {
      final PaywallCubit paywallCubit = AppConfig.instance.context!.read<PaywallCubit>();
      AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(AppConfig.instance.context!, true);
      DMessage.showMessage(
        message: AppConfig.instance.context?.text.monetPaymentSuccessToast ?? '',
        type: MessageType.success,
      );
      await PremiumPopupProductionUnlock.show(AppConfig.instance.context!);
      await paywallCubit.showFeedbackPaywallDialog();
    });
  }

  void _onPurchaseFailure({String error = ''}) {
    emit(state.copyWith(isLoading: false));
    _trackingService.trackPaywallStorePopupDismiss(AppConfig.instance.context!  , state.selectedProductId);
    DMessage.showMessage(message: error.isEmpty ? AppConfig.instance.context?.text.monetPaymentFailToast ?? '' : error, type: MessageType.error);
  }

  @override
  Future<void> close() {
    _purchaseDetailSubscription?.cancel();
    return super.close();
  }
}
