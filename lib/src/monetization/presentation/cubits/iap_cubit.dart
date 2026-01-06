part of '../../monetization.dart';

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
  final Set<String> _verifyingTransactionIds = {};
  final Map<String, List<PurchaseDetails>> _pendingReceiptQueue = {};
  Timer? _restoreTimeout;
  bool _ignoreHandledOnce = false; // bypass dedup once for user-triggered flows

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
    if (state.iapProducts.isNotEmpty) return;
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

  Future<void> purchaseProduct({bool isHighlight = false, PurchaseOrigin origin = PurchaseOrigin.paywall}) async {
    if (state.iapProducts.isEmpty) {
      _onPurchaseFailure(error: AppConfig.instance.context?.text.monetization.emptyProductsDesc ?? '');
      return;
    }

    if (state.status == MonetizationStatus.purchasing) return;
    String productId = isHighlight ? state.bestDealProduct.productId : state.selectedProduct.productId;
    _ignoreHandledOnce = true; // user-initiated purchase; allow next receipt even if duplicate
    emit(
      state.copyWith(
        status: MonetizationStatus.purchasing,
        lastAction: PurchaseAction.purchase,
        lastOrigin: origin,
      ),
    );
    await runUseCase<IapVerifyEntity>(
      usecase: () => _purchaseUsecase.call(PurchaseParams(productId: productId, type: state.selectedProduct.type)),
      onSuccess: (verify) {
        emit(state.copyWith(status: MonetizationStatus.initial));
      },
      onFailure: (error) => _onPurchaseFailure(),
    );
  }

  Future<void> restorePurchases({PurchaseOrigin origin = PurchaseOrigin.paywall}) async {
    if (state.status == MonetizationStatus.restoring) return;
    emit(
      state.copyWith(
        status: MonetizationStatus.restoring,
        lastAction: PurchaseAction.restore,
        lastOrigin: origin,
      ),
    );
    _ignoreHandledOnce = true; // user-initiated restore; allow next receipt even if duplicate

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
      final transactionId = purchaseDetail.transactionId;

      switch (purchaseDetail.status) {
        case PurchaseStatus.pending:
          _onPurchasePending();
          LogDev.warning('Payment is pending');
          break;
        case PurchaseStatus.canceled:
          _onPurchaseFailure();
          _markHandled(transactionId);
          _clearPendingReceipts(transactionId);
          _verifyingTransactionIds.remove(transactionId);
          _restoreTimeout?.cancel();
          await _finishTransaction(purchaseDetail);
          LogDev.warning('Payment is canceled');

          break;
        case PurchaseStatus.error:
          _onPurchaseFailure();
          _markHandled(transactionId);
          _clearPendingReceipts(transactionId);
          _verifyingTransactionIds.remove(transactionId);
          _restoreTimeout?.cancel();
          await _finishTransaction(purchaseDetail);
          _trackingService.trackSubscriptionFailed(state.selectedProductId);
          LogDev.warning('Payment failed');

          break;
        case PurchaseStatus.purchased:
          await _handleVerificationQueue(purchaseDetail, transactionId);
          LogDev.warning('Purchase verification handled');
          break;

        case PurchaseStatus.restored:
          await _handleVerificationQueue(purchaseDetail, transactionId);
          LogDev.warning('Purchase restored');
          break;
      }
    });
  }

  Future<void> _handleVerificationQueue(PurchaseDetails purchaseDetail, String transactionId) async {
    if (_alreadyHandled(transactionId)) {
      await _safeFinishTransaction(purchaseDetail);
      return;
    }

    if (transactionId.isNotEmpty && _verifyingTransactionIds.contains(transactionId)) {
      _enqueuePendingReceipt(transactionId, purchaseDetail);
      LogDev.info('Queued duplicate receipt for transaction: $transactionId');
      return;
    }

    if (transactionId.isNotEmpty) {
      _verifyingTransactionIds.add(transactionId);
    }

    PurchaseDetails currentDetail = purchaseDetail;
    while (true) {
      final isVerified = await _verifyPurchase(currentDetail, transactionId);

      if (isVerified) {
        if (transactionId.isNotEmpty) {
          _markHandled(transactionId);
        }
        _onPurchaseSuccess(currentDetail);
        if (transactionId.isNotEmpty) {
          await _discardPendingReceipts(transactionId);
          _verifyingTransactionIds.remove(transactionId);
        }
        return;
      }

      await _safeFinishTransaction(currentDetail);
      if (transactionId.isEmpty) {
        _onPurchaseFailure(error: AppConfig.instance.context?.text.monetization.verificationFailToast ?? '');
        return;
      }

      final nextDetail = _dequeuePendingReceipt(transactionId);
      if (nextDetail == null) {
        _markHandled(transactionId);
        _verifyingTransactionIds.remove(transactionId);
        _onPurchaseFailure(error: AppConfig.instance.context?.text.monetization.verificationFailToast ?? '');
        return;
      }

      currentDetail = nextDetail;
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetail, String transactionId) async {
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

    bool isSuccess = false;
    await runUseCase<IapVerifyEntity>(
      usecase: () => _verifyUsecase.call(params),
      onSuccess: (verify) {
        isSuccess = true;
      },
      onFailure: (error) => isSuccess = false,
    );
    return isSuccess;
  }

  void _onPurchaseSuccess(PurchaseDetails purchaseDetail) {
    _restoreTimeout?.cancel();
    _finishTransaction(purchaseDetail);
    AppDI.injector.get<ProfileCubit>().loadUser();
    if (state.lastOrigin != PurchaseOrigin.paywall) {
      AppConfig.instance.context?.back();
    }
    _trackingService.trackSubscriptionCompleted(state.selectedProductId);

    Future.delayed(const Duration(seconds: 1), () async {
      bool hasSubscription = AppDI.injector.get<ProfileCubit>().state.user.iapSubscriptions.isNotEmpty;
      emit(state.copyWith(status: MonetizationStatus.purchaseSuccess));
      AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(AppConfig.instance.context!, true);
      if (hasSubscription) return;
      DMessage.showMessage(
        message: AppConfig.instance.context?.text.monetization.subscriptionActiveToast ?? '',
        type: MessageType.success,
      );
      // await PremiumPopupProductionUnlock.show(AppConfig.instance.context!);
    });
  }

  void _onPurchaseFailure({String error = ''}) {
    emit(
      state.copyWith(
        status: MonetizationStatus.failure,
        errorMessage: error.toString(),
        lastAction: PurchaseAction.none,
        lastOrigin: PurchaseOrigin.none,
      ),
    );
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

  bool _alreadyHandled(String transactionId) {
    if (_ignoreHandledOnce) {
      _ignoreHandledOnce = false; // consume bypass
      return false;
    }
    return transactionId.isNotEmpty && _processedTransactionIds.contains(transactionId);
  }

  void _markHandled(String transactionId) {
    if (transactionId.isEmpty) return;
    _processedTransactionIds.add(transactionId);
    _persistProcessedTransactions();
  }

  void _enqueuePendingReceipt(String transactionId, PurchaseDetails purchaseDetail) {
    final queue = _pendingReceiptQueue.putIfAbsent(transactionId, () => []);
    queue.add(purchaseDetail);
  }

  PurchaseDetails? _dequeuePendingReceipt(String transactionId) {
    final queue = _pendingReceiptQueue[transactionId];
    if (queue == null || queue.isEmpty) return null;
    final next = queue.removeAt(0);
    if (queue.isEmpty) {
      _pendingReceiptQueue.remove(transactionId);
    }
    return next;
  }

  Future<void> _discardPendingReceipts(String transactionId) async {
    final queue = _pendingReceiptQueue.remove(transactionId);
    if (queue == null || queue.isEmpty) return;
    for (final pending in queue) {
      await _safeFinishTransaction(pending);
    }
  }

  void _clearPendingReceipts(String transactionId) {
    _pendingReceiptQueue.remove(transactionId);
  }

  void consumePurchaseSuccess() {
    if (state.status != MonetizationStatus.purchaseSuccess) return;
    emit(
      state.copyWith(
        status: MonetizationStatus.initial,
        lastAction: PurchaseAction.none,
        lastOrigin: PurchaseOrigin.none,
      ),
    );
  }

  Future<void> _safeFinishTransaction(PurchaseDetails purchaseDetail) async {
    try {
      await _finishTransaction(purchaseDetail);
    } catch (e) {
      LogDev.warning('Failed to finish transaction: $e');
    }
  }

  Future<void> _finishTransaction(PurchaseDetails purchaseDetail) async => await _iapService.completePurchase(purchaseDetail);

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
