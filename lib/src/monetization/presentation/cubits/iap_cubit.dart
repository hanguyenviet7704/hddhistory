part of '../../monetization.dart';

@visibleForTesting
bool shouldPreparePaywallAutoOpen({
  required bool enabled,
  required int sessionRolloutPercent,
  required int rolloutBucket,
  required bool isSuppressed,
  required bool hasCompletedOnboarding,
  required String userId,
  required String accessToken,
  required bool isPremium,
}) {
  if (isSuppressed) return false;
  if (!enabled) return false;
  if (sessionRolloutPercent <= 0 || sessionRolloutPercent > 100) return false;
  if (rolloutBucket < 0 || rolloutBucket > 99) return false;
  if (rolloutBucket >= sessionRolloutPercent) return false;
  if (!hasCompletedOnboarding) return false;
  if (userId.trim().isEmpty || accessToken.trim().isEmpty) return false;
  if (isPremium) return false;
  return true;
}

@lazySingleton
class IapCubit extends Cubit<IapState> with CubitUseCaseHandlerMixin<IapState> {
  final IMonetizationRepository _iapRepository;
  final IIapService _iapService;
  final ITrackingService _trackingService;
  final GetPackagesUsecase _getPackagesUsecase;
  final PurchaseUsecase _purchaseUsecase;
  final RestoreUsecase _restoreUsecase;
  final VerifyUsecase _verifyUsecase;
  final ResolvePaywallStrategyUsecase _resolvePaywallStrategyUsecase;
  final IRemoteConfigService _remoteConfigService;

  final IPackageInfoService _packageInfoService;

  PaywallEntryPoint _paywallEntryPoint = PaywallEntryPoint.other;
  CourseTrackingData? _paywallCourseTrackingData;
  bool _autoOpenSuppressed = false;
  bool _autoOpenEvaluated = false;
  int? _autoOpenRolloutBucket;
  Future<bool>? _autoOpenPrepareFuture;

  IapCubit(
    this._iapRepository,
    this._iapService,
    this._trackingService,
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
    this._verifyUsecase,
    this._resolvePaywallStrategyUsecase,
    this._remoteConfigService,
    this._packageInfoService,
  ) : super(IapState.initial());

  PaywallEntryPoint get paywallEntryPoint => _paywallEntryPoint;
  CourseTrackingData? get paywallCourseTrackingData => _paywallCourseTrackingData;

  void setPaywallEntryPoint(
    PaywallEntryPoint entryPoint, {
    CourseTrackingData? trackingData,
  }) {
    _paywallEntryPoint = entryPoint;
    if (entryPoint == PaywallEntryPoint.courseRoadmap) {
      _paywallCourseTrackingData = trackingData;
    } else {
      _paywallCourseTrackingData = null;
    }
  }

  void resetPaywallEntryPoint() {
    setPaywallEntryPoint(PaywallEntryPoint.other);
  }

  @visibleForTesting
  void debugSetAutoOpenRolloutBucket(int bucket) {
    _autoOpenRolloutBucket = bucket.clamp(0, 99);
  }

  void suppressPaywallAutoOpenForSession() {
    _autoOpenSuppressed = true;
  }

  StreamSubscription<PurchaseDetails>? _purchaseDetailSubscription;
  final Set<String> _processedTransactionIds = {};
  final Set<String> _verifyingTransactionIds = {};
  final Map<String, List<PurchaseDetails>> _pendingReceiptQueue = {};
  Future<bool>? _loadIapProductsFuture;
  String? _loadIapProductsSignature;
  int _loadIapProductsGeneration = 0;
  Timer? _restoreTimeout;
  bool _ignoreHandledOnce = false; // bypass dedup once for user-triggered flows

  void setSelectedProductId(String productId) {
    emit(state.copyWith(selectedProductId: productId));
    // purchaseProduct();
  }

  Future<void> recordPaywallRenderedImpression() async {
    final strategy = state.resolvedPaywallStrategy;
    if (strategy == null || !strategy.isValid || state.iapProducts.isEmpty) return;
    if (strategy.segment != ResolvedPaywallSegment.newUser) return;

    final currentCount = await _iapRepository.getNewUserPaywallImpressionCount();
    final renderedCount = strategy.impressionNumber ?? currentCount + 1;
    if (renderedCount <= currentCount) return;
    await _iapRepository.setNewUserPaywallImpressionCount(renderedCount);
  }

  Future<bool> prepareAutoOpenPaywall({
    required String userId,
    required String accessToken,
    required bool hasCompletedOnboarding,
    required bool isPremium,
    required Future<bool?> Function() refreshPremiumStatus,
  }) {
    final inFlight = _autoOpenPrepareFuture;
    if (inFlight != null) return inFlight;
    if (_autoOpenSuppressed || _autoOpenEvaluated) return Future.value(false);

    _autoOpenEvaluated = true;
    final task = _prepareAutoOpenPaywall(
      userId: userId,
      accessToken: accessToken,
      hasCompletedOnboarding: hasCompletedOnboarding,
      isPremium: isPremium,
      refreshPremiumStatus: refreshPremiumStatus,
    );
    _autoOpenPrepareFuture = task;
    return task.whenComplete(() {
      if (identical(_autoOpenPrepareFuture, task)) {
        _autoOpenPrepareFuture = null;
      }
    });
  }

  Future<bool> _prepareAutoOpenPaywall({
    required String userId,
    required String accessToken,
    required bool hasCompletedOnboarding,
    required bool isPremium,
    required Future<bool?> Function() refreshPremiumStatus,
  }) async {
    final config = _remoteConfigService.paywallConfig.autoOpen;
    final bucket = _autoOpenRolloutBucket ??= Random().nextInt(100);
    if (!shouldPreparePaywallAutoOpen(
      enabled: config.enabled,
      sessionRolloutPercent: config.sessionRolloutPercent,
      rolloutBucket: bucket,
      isSuppressed: _autoOpenSuppressed,
      hasCompletedOnboarding: hasCompletedOnboarding,
      userId: userId,
      accessToken: accessToken,
      isPremium: isPremium,
    )) {
      return false;
    }

    bool? refreshedPremium;
    try {
      refreshedPremium = await refreshPremiumStatus();
    } catch (_) {
      refreshedPremium = null;
    }
    if (refreshedPremium != false) return false;

    final isReady = await loadIapProducts();
    if (!isReady || state.iapProducts.isEmpty) return false;
    setPaywallEntryPoint(PaywallEntryPoint.autoOpen);
    return true;
  }

  Future<void> init() async {
    await _loadProcessedTransactions();
    _subscribeToPurchaseUpdates();
  }

  void disposeStreamSubscription() {
    _purchaseDetailSubscription?.cancel();
    _purchaseDetailSubscription = null;
  }

  Future<bool> loadIapProducts({bool forceRetry = false}) async {
    final platform = PaymentPlatform.fromDevicePlatform;
    final storedImpressionCount = await _iapRepository.getNewUserPaywallImpressionCount();
    final resolvedStrategy = _resolvePaywallStrategyUsecase(
      ResolvePaywallStrategyParams(
        config: _remoteConfigService.paywallConfig,
        platform: platform,
        nowUtc: DateTime.now().toUtc(),
        installTime: _installTime,
        storedImpressionCount: storedImpressionCount,
      ),
    );

    if (!resolvedStrategy.isValid) {
      emit(
        state.copyWith(
          status: MonetizationStatus.failure,
          iapProducts: [],
          selectedProductId: '',
          resolvedPaywallStrategy: resolvedStrategy,
          paywallContent: resolvedStrategy.content,
          paywallStrategySignature: resolvedStrategy.signature,
          errorMessage: resolvedStrategy.invalidReason,
        ),
      );
      return false;
    }

    if (!forceRetry && state.iapProducts.isNotEmpty && state.paywallStrategySignature == resolvedStrategy.signature) {
      return true;
    }

    final loadingSignature = resolvedStrategy.signature;
    if (!forceRetry && _loadIapProductsFuture != null && _loadIapProductsSignature == loadingSignature) {
      return _loadIapProductsFuture!;
    }

    final generation = ++_loadIapProductsGeneration;
    _loadIapProductsSignature = loadingSignature;
    _loadIapProductsFuture = _loadResolvedIapProducts(
      platform: platform,
      resolvedStrategy: resolvedStrategy,
      loadingSignature: loadingSignature,
      generation: generation,
    );

    try {
      return await _loadIapProductsFuture!;
    } finally {
      if (_loadIapProductsSignature == loadingSignature && _loadIapProductsGeneration == generation) {
        _loadIapProductsSignature = null;
        _loadIapProductsFuture = null;
      }
    }
  }

  Future<bool> _loadResolvedIapProducts({
    required PaymentPlatform platform,
    required ResolvedPaywallStrategyEntity resolvedStrategy,
    required String loadingSignature,
    required int generation,
  }) async {
    emit(state.copyWith(status: MonetizationStatus.loading, errorMessage: null, paywallStrategySignature: loadingSignature));
    final result = await _getPackagesUsecase.call(GetPackagesParams(platform: platform, selectedProductIds: resolvedStrategy.productIds)).run();
    return result.match(
      (error) {
        if (!_isCurrentLoad(loadingSignature, generation)) return false;
        emit(
          state.copyWith(
            status: MonetizationStatus.failure,
            iapProducts: [],
            selectedProductId: '',
            resolvedPaywallStrategy: resolvedStrategy,
            paywallContent: resolvedStrategy.content,
            errorMessage: error.toString(),
          ),
        );
        return false;
      },
      (products) {
        if (!_isCurrentLoad(loadingSignature, generation)) return false;
        if (products.isEmpty) {
          emit(
            state.copyWith(
              status: MonetizationStatus.failure,
              iapProducts: [],
              selectedProductId: '',
              resolvedPaywallStrategy: resolvedStrategy,
              paywallContent: resolvedStrategy.content,
              errorMessage: 'empty_products',
            ),
          );
          return false;
        }
        final selectedProduct = _defaultSelectedProduct(products);
        emit(
          state.copyWith(
            status: MonetizationStatus.success,
            iapProducts: products,
            selectedProductId: selectedProduct.id,
            resolvedPaywallStrategy: resolvedStrategy,
            paywallContent: resolvedStrategy.content,
            paywallStrategySignature: loadingSignature,
            errorMessage: null,
          ),
        );
        return true;
      },
    );
  }

  bool _isCurrentLoad(String signature, int generation) {
    return state.paywallStrategySignature == signature && _loadIapProductsSignature == signature && _loadIapProductsGeneration == generation;
  }

  DateTime? get _installTime {
    try {
      return (_packageInfoService.packageInfo as dynamic).installTime as DateTime?;
    } catch (_) {
      return null;
    }
  }

  IapProductEntity _defaultSelectedProduct(List<IapProductEntity> products) {
    for (final product in products) {
      if (product.bestDeal) return product;
    }
    return products.first;
  }

  Future<void> purchaseProduct({bool isHighlight = false, PurchaseOrigin origin = PurchaseOrigin.paywall}) async {
    if (state.iapProducts.isEmpty) {
      _onPurchaseFailure(error: l10n.monetization.emptyProductsDesc);
      return;
    }

    if (state.status == MonetizationStatus.purchasing) return;
    final product = isHighlight ? state.bestDealProduct : state.selectedProduct;
    String productId = product.productId;
    _ignoreHandledOnce = true; // user-initiated purchase; allow next receipt even if duplicate
    emit(
      state.copyWith(
        status: MonetizationStatus.purchasing,
        lastAction: PurchaseAction.purchase,
        lastOrigin: origin,
      ),
    );
    await runUseCase<IapVerifyEntity>(
      usecase: () => _purchaseUsecase.call(PurchaseParams(productId: productId, type: product.type)),
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
      message: l10n.monetization.restoreProcessingToast,
      type: MessageType.info,
    );

    _restoreTimeout = Timer(const Duration(seconds: 6), () {
      if (state.status != MonetizationStatus.restoring) return;
      emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: 'restore_timeout'));
      DMessage.showMessage(
        message: l10n.monetization.restoreNotFoundToast,
        type: MessageType.error,
      );
    });

    await runUseCase<IapVerifyEntity>(
      usecase: () => _restoreUsecase(unit),
      onSuccess: (verify) {
        // Actual restored purchases will come through the purchase stream; keep awaiting until then.
      },
      onFailure: (error) {
        _restoreTimeout?.cancel();
        emit(state.copyWith(status: MonetizationStatus.failure, errorMessage: error.toString()));
        DMessage.showMessage(
          message: l10n.monetization.paymentFailToast,
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
        _onPurchaseFailure(error: l10n.monetization.verificationFailToast);
        return;
      }

      final nextDetail = _dequeuePendingReceipt(transactionId);
      if (nextDetail == null) {
        _markHandled(transactionId);
        _verifyingTransactionIds.remove(transactionId);
        _onPurchaseFailure(error: l10n.monetization.verificationFailToast);
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
    if (state.lastOrigin != PurchaseOrigin.paywall) {
      AppConfig.instance.context?.back();
    }
    _trackingService.trackSubscriptionCompleted(state.selectedProductId);

    Future.delayed(const Duration(seconds: 1), () async {
      bool hasSubscription = AppDI.injector.get<ProfileCubit>().state.user.iapSubscriptions.isNotEmpty;
      AppDI.injector.get<ProfileCubit>().loadUser();
      emit(state.copyWith(status: MonetizationStatus.purchaseSuccess));
      if (hasSubscription) return;
      DMessage.showMessage(
        message: l10n.monetization.subscriptionActiveToast,
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
    DMessage.showMessage(
      message: error.isEmpty ? l10n.monetization.paymentFailToast : error,
      type: MessageType.error,
    );
  }

  void _onPurchasePending() {
    emit(state.copyWith(status: MonetizationStatus.initial));
    DMessage.showMessage(
      message: l10n.monetization.paymentPendingToast,
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
