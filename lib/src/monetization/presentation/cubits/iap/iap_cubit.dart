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

  final IPackageInfoService _packageInfoService;

  IapCubit(
    this._iapRepository,
    this._iapService,
    this._trackingService,
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
    this._verifyUsecase,
    this._packageInfoService,
  ) : super(IapState.initial());

  StreamSubscription<PurchaseDetails>? _purchaseDetailSubscription;
  final Set<String> _processedTransactionIds = {};
  Timer? _restoreTimeout;

  void setSelectedProductId(String productId) {
    emit(state.copyWith(selectedProductId: productId));
    // purchaseProduct();
  }

  Future<void> init() async {
    await _loadProcessedTransactions();
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
        String largestProductPriceId = products.reduce((a, b) => a.rawPrice > b.rawPrice ? a : b).id;
        emit(state.copyWith(iapProducts: products, selectedProductId: largestProductPriceId));
      },
      onFailure: (error) => emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString())),
    );
  }

  Future<void> purchaseProduct({bool isHighlight = false}) async {
    if (state.iapProducts.isEmpty) {
      _onPurchaseFailure(error: AppConfig.instance.context?.text.monetization.emptyProductsDesc ?? '');
      return;
    }

    if (state.status == MonetizationStatus.purchasing) return;
    String productId = isHighlight ? state.bestDealProduct.productId : state.selectedProduct.productId;
    emit(state.copyWith(status: MonetizationStatus.purchasing));
    await runUseCase<IapVerifyEntity>(
      usecase: () => _purchaseUsecase.call(PurchaseParams(productId: productId, type: state.selectedProduct.type)),
      onSuccess: (verify) {},
      onFailure: (error) => _onPurchaseFailure(),
    );
  }

  Future<void> restorePurchases() async {
    if (state.status == MonetizationStatus.restoring) return;
    emit(state.copyWith(status: MonetizationStatus.restoring));
    
    _restoreTimeout?.cancel();
    DMessage.showMessage(
      message: AppConfig.instance.context?.text.monetization.restoreProcessingToast ?? '',
      type: MessageType.info,
    );

    _restoreTimeout = Timer(const Duration(seconds: 6), () {
      if (state.status != MonetizationStatus.restoring) return;
      emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: 'restore_timeout'));
      DMessage.showMessage(
        message: AppConfig.instance.context?.text.monetization.restoreNotFoundToast ?? '',
        type: MessageType.error,
      );
    });

    await runUseCase<IapVerifyEntity>(
      usecase: _restoreUsecase.call,
      onSuccess: (verify) {
        // Actual restored purchases will come through the purchase stream; keep awaiting until then.
      },
      onFailure: (error) {
        _restoreTimeout?.cancel();
        emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString()));
        DMessage.showMessage(
          message: AppConfig.instance.context?.text.monetization.paymentFailToast ?? '',
          type: MessageType.error,
        );
      },
    );
  }

  Future<void> _subscribeToPurchaseUpdates() async {
    if (_purchaseDetailSubscription != null) return;

    _purchaseDetailSubscription = _iapRepository.purchaseDetailStream.listen((purchaseDetail) async {
      final transactionId = _transactionIdOf(purchaseDetail);

      switch (purchaseDetail.status) {
        case PurchaseStatus.pending:
          _onPurchasePending();
          LogDev.warning('Payment is pending');
          break;
        case PurchaseStatus.canceled:
          _onPurchaseFailure();
          _markHandled(transactionId);
          _restoreTimeout?.cancel();
          await _finishTransaction(purchaseDetail);
          LogDev.warning('Payment is canceled');

          break;
        case PurchaseStatus.error:
          _onPurchaseFailure();
          _markHandled(transactionId);
          _restoreTimeout?.cancel();
          await _finishTransaction(purchaseDetail);
          _trackingService.trackSubscriptionFailed(state.selectedProductId);
          LogDev.warning('Payment failed');

          break;
        case PurchaseStatus.purchased:
          if (_alreadyHandled(transactionId)) {
            await _finishTransaction(purchaseDetail);
            return;
          }
          _verifyPurchase(purchaseDetail, transactionId);
          LogDev.warning('Purchase verification done');
          break;

        case PurchaseStatus.restored:
          if (_alreadyHandled(transactionId)) {
            await _finishTransaction(purchaseDetail);
            return;
          }
          _verifyPurchase(purchaseDetail, transactionId);
          LogDev.warning('Purchase restored');
          break;
      }
    });
  }

  void _verifyPurchase(PurchaseDetails purchaseDetail, String transactionId) async {
    late VerifyParams params;

    if (Platform.isIOS) {
      params = VerifyParams(
        platform: PaymentPlatform.apple,
        productId: purchaseDetail.productID,
        packageName: _packageInfoService.packageName,
        storeTransactionId: transactionId,
      );
    } else {
      final verificationData = purchaseDetail.verificationData;
      params = VerifyParams(
        platform: PaymentPlatform.google,
        productId: purchaseDetail.productID,
        packageName: _packageInfoService.packageName,
        storeTransactionId: verificationData.serverVerificationData,
      );
    }

    runUseCase<IapVerifyEntity>(
      usecase: () => _verifyUsecase.call(params),
      onSuccess: (verify) {
        _markHandled(transactionId);
        _onPurchaseSuccess(purchaseDetail, isRestore: purchaseDetail.status == PurchaseStatus.restored);
      },
      onFailure: (error) {
        _markHandled(transactionId);
        _onPurchaseFailure(error: AppConfig.instance.context?.text.monetization.verificationFailToast ?? '');
        _finishTransaction(purchaseDetail);
      },
    );
  }

  void _onPurchaseSuccess(PurchaseDetails purchaseDetail, {bool isRestore = false}) {
    _restoreTimeout?.cancel();
    _finishTransaction(purchaseDetail);
    AppDI.injector.get<ProfileCubit>().loadUser();
    AppConfig.instance.context?.back();
    _trackingService.trackSubscriptionCompleted(state.selectedProductId);

    Future.delayed(const Duration(seconds: 1), () async {
      emit(state.copyWith(status: MonetizationStatus.purchaseSuccess));
      AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(AppConfig.instance.context!, true);
      DMessage.showMessage(
        message: isRestore
            ? AppConfig.instance.context?.text.monetization.restoreSuccessToast ?? ''
            : AppConfig.instance.context?.text.monetization.paymentSuccessToast ?? '',
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

  void _onPurchasePending() {
    emit(state.copyWith(status: MonetizationStatus.initial));
    DMessage.showMessage(
      message: AppConfig.instance.context?.text.monetization.paymentPendingToast ?? '',
      type: MessageType.info,
    );
  }

  bool _alreadyHandled(String transactionId) => transactionId.isNotEmpty && _processedTransactionIds.contains(transactionId);

  void _markHandled(String transactionId) {
    if (transactionId.isEmpty) return;
    _processedTransactionIds.add(transactionId);
    _persistProcessedTransactions();
  }

  String _transactionIdOf(PurchaseDetails purchaseDetail) =>
      purchaseDetail.purchaseID?.trim().isNotEmpty == true
          ? purchaseDetail.purchaseID!
          : purchaseDetail.verificationData.serverVerificationData;

  Future<void> _finishTransaction(PurchaseDetails purchaseDetail) async {
    if (purchaseDetail.pendingCompletePurchase) {
      await _iapService.completePurchase(purchaseDetail);
    }
  }

  Future<void> _loadProcessedTransactions() async {
    final ids = await _iapRepository.loadProcessedTransactionIds();
    _processedTransactionIds.addAll(ids.take(100));
  }

  Future<void> _persistProcessedTransactions() async {
    final ids = _processedTransactionIds.take(100).toList();
    await _iapRepository.cacheProcessedTransactionIds(ids);
  }

  @override
  Future<void> close() {
    _purchaseDetailSubscription?.cancel();
    return super.close();
  }
}
