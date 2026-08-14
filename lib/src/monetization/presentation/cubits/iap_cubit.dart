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
  final ValidateVoucherUsecase _validateVoucherUsecase;
  final IRemoteConfigService _remoteConfigService;
  final GetPaywallConfigUsecase _getPaywallConfigUsecase;
  final GetPaywallLogicSaleUsecase _getPaywallLogicSaleUsecase;

  final IPackageInfoService _packageInfoService;

  PaywallEntryPoint _paywallEntryPoint = PaywallEntryPoint.other;
  CourseTrackingData? _paywallCourseTrackingData;
  bool _autoOpenSuppressed = false;
  bool _autoOpenEvaluated = false;
  int? _autoOpenRolloutBucket;
  Future<bool>? _autoOpenPrepareFuture;

  // Paywall config resolution chain: API -> last cached API response ->
  // Remote Config -> Remote Config's own bundled defaults. `null` means
  // "the API/cache layer hasn't produced anything yet" and makes
  // `resolvedPaywallConfig` fall through live to Remote Config, so a cold
  // start with no network still renders instead of blocking or going blank.
  PaywallConfigEntity? _resolvedPaywallConfig;
  Future<void>? _prefetchPaywallConfigFuture;

  IapCubit(
    this._iapRepository,
    this._iapService,
    this._trackingService,
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
    this._verifyUsecase,
    this._resolvePaywallStrategyUsecase,
    this._validateVoucherUsecase,
    this._remoteConfigService,
    this._getPaywallConfigUsecase,
    this._getPaywallLogicSaleUsecase,
    this._packageInfoService,
  ) : super(IapState.initial());

  /// Best available paywall config right now — never awaits a network call.
  /// Read by the paywall (via [loadIapProducts]/[_prepareAutoOpenPaywall])
  /// and by course-roadmap lesson-lock checks. Call [prefetchPaywallConfig]
  /// (app start + whenever the paywall is about to open) to keep this fresh;
  /// this getter itself is always synchronous and always non-null.
  PaywallConfigEntity get resolvedPaywallConfig => _resolvedPaywallConfig ?? _remoteConfigService.paywallConfig;

  /// Refreshes [resolvedPaywallConfig] from the API in the background.
  ///
  /// Never blocks: callers should fire-and-forget this (see
  /// `AppService._configService` and [loadIapProducts]) and read
  /// [resolvedPaywallConfig] immediately for whatever is already resolved.
  /// Concurrent calls share one in-flight fetch instead of stacking requests.
  Future<void> prefetchPaywallConfig() {
    final inFlight = _prefetchPaywallConfigFuture;
    if (inFlight != null) return inFlight;

    final task = _prefetchPaywallConfig();
    _prefetchPaywallConfigFuture = task;
    return task.whenComplete(() {
      if (identical(_prefetchPaywallConfigFuture, task)) {
        _prefetchPaywallConfigFuture = null;
      }
    });
  }

  Future<void> _prefetchPaywallConfig() async {
    final result = await _getPaywallConfigUsecase(unit).run();
    result.match(
      (_) {
        // API failed and there is no cached response either: keep whatever
        // is already resolved (a previous successful fetch, or — via the
        // getter's fallback — Remote Config/bundled defaults). Never clear
        // a good value just because a background refresh failed.
      },
      (config) => _resolvedPaywallConfig = config,
    );
  }

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
    _paywallVariantOverride = null;
  }

  // A caller that KNOWS which surface it wants, overriding the entry-point
  // table: the gift popup always opens the ABBREVIATED paywall (spec sheet),
  // and an admin deeplink can name either variant outright
  // (`meup://paywall?variant=full|compact`). Reset together with the entry
  // point (PaywallPage.dispose), so the override can never leak into a later,
  // ordinary paywall open.
  PaywallProductVariant? _paywallVariantOverride;
  PaywallProductVariant? get paywallVariantOverride => _paywallVariantOverride;
  void forcePaywallVariant(PaywallProductVariant variant) => _paywallVariantOverride = variant;

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

  /// Set by [_verifyPurchase] when the server refused for a reason the buyer
  /// can actually act on, so the generic toast can be replaced with it. Reset
  /// on every attempt — a queued retry must not inherit the last one's reason.
  String? _verifyRefusalMessage;

  void setSelectedProductId(String productId) {
    emit(state.copyWith(selectedProductId: productId));
    // purchaseProduct();
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
    final config = resolvedPaywallConfig.autoOpen;
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

    // Set BEFORE loading, not after: the entry point is what decides which SKU
    // list gets loaded, so loading first would fetch whatever the previous
    // entry point resolved to and then need a second fetch on the paywall
    // itself. Restored on failure so a prepare that never opened a paywall does
    // not leave `autoOpen` behind for the next screen's tracking.
    final previousEntryPoint = _paywallEntryPoint;
    setPaywallEntryPoint(PaywallEntryPoint.autoOpen);

    final isReady = await loadIapProducts();
    if (!isReady || state.iapProducts.isEmpty) {
      setPaywallEntryPoint(previousEntryPoint);
      return false;
    }
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
    // Refresh policy: re-fetch whenever the paywall is about to open, but
    // never wait on it — this call renders with whatever is already
    // resolved, and a fresher value (if any) lands in time for the next open.
    unawaited(prefetchPaywallConfig());

    final platform = PaymentPlatform.fromDevicePlatform;
    final resolvedStrategy = _resolvePaywallStrategyUsecase(
      ResolvePaywallStrategyParams(
        config: resolvedPaywallConfig,
        platform: platform,
        nowUtc: DateTime.now().toUtc(),
        // Entry point is always set before the paywall is pushed (and before
        // this load, in the auto-open path), so it is current by the time the
        // strategy resolves.
        entryPoint: _paywallEntryPoint,
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
    // The strategy goes into state HERE, not when the store answers. Which
    // paywall this is — full page or compact sheet — is decided synchronously
    // from the config and the entry point; it never depends on the fetch. Held
    // back until the products landed, the page spent the whole fetch drawing
    // the PREVIOUS open's variant and then snapped to this one, which read as
    // the paywall flickering between rút gọn and đầy đủ (2026-08-09). The
    // prices below it still arrive late; the layout no longer does.
    emit(
      state.copyWith(
        status: MonetizationStatus.loading,
        errorMessage: null,
        paywallStrategySignature: loadingSignature,
        resolvedPaywallStrategy: resolvedStrategy,
        paywallContent: resolvedStrategy.content,
      ),
    );

    // Fired alongside the store product fetch below, not before it: this is
    // the same "fire and let the current load await it" shape as the store
    // fetch itself, just for a second, independent signal. A failure or
    // `active: false` answer resolves to null, so everything past this line
    // behaves exactly as it did before LogicSale existed.
    final logicSale = await _resolveLogicSale(resolvedStrategy);
    if (!_isCurrentLoad(loadingSignature, generation)) return false;

    final logicSaleProductIds = _logicSaleProductIds(logicSale, platform);
    final usesLogicSale = logicSaleProductIds.isNotEmpty;
    final productIds = usesLogicSale ? logicSaleProductIds : resolvedStrategy.productIds;

    final result = await _getPackagesUsecase.call(GetPackagesParams(platform: platform, selectedProductIds: state.applyVoucherSwap(productIds))).run();
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
            logicSaleId: '',
            logicSaleCountdownEndAt: null,
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
              logicSaleId: '',
              logicSaleCountdownEndAt: null,
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
            logicSaleId: usesLogicSale ? logicSale!.id : '',
            // Tied to the override actually taking effect, not just `active:
            // true` — a countdown over a product list that quietly fell back
            // to the default plans would misrepresent what the clock is
            // counting down to.
            logicSaleCountdownEndAt: usesLogicSale && logicSale!.countdown ? _logicSaleLocalDeadline(logicSale) : null,
          ),
        );
        return true;
      },
    );
  }

  bool _isCurrentLoad(String signature, int generation) {
    return state.paywallStrategySignature == signature && _loadIapProductsSignature == signature && _loadIapProductsGeneration == generation;
  }

  /// LogicSale never touches the compact 33%-off sheet — the same rule
  /// `saleStrategy.saleEvent` follows (see `ResolvePaywallStrategyUsecase`).
  Future<PaywallLogicSaleEntity?> _resolveLogicSale(ResolvedPaywallStrategyEntity resolvedStrategy) async {
    if (resolvedStrategy.variant == PaywallProductVariant.compact) return null;
    final result = await _getPaywallLogicSaleUsecase(unit).run();
    return result.match((_) => null, (value) => value.active ? value : null);
  }

  /// Platform-appropriate SKU per reference, skipping any that is missing
  /// the current platform's id entirely — unlike the sale-event resolver,
  /// one bad reference here does not invalidate the whole list, it is simply
  /// left out.
  List<String> _logicSaleProductIds(PaywallLogicSaleEntity? logicSale, PaymentPlatform platform) {
    if (logicSale == null) return const [];
    final ids = <String>[];
    for (final product in logicSale.products) {
      final id = switch (platform) {
        PaymentPlatform.apple => product.appleProductId,
        PaymentPlatform.google || PaymentPlatform.unknown => product.googleProductId,
      };
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) ids.add(trimmed);
    }
    return ids;
  }

  /// Translates the campaign's server-clock deadline onto this device's own
  /// clock, once, at fetch time: `remaining = endAtUtc - nowUtc` is measured
  /// entirely on the server's numbers, then re-anchored to `DateTime.now()`
  /// here so every later tick (see `_LogicSaleCountdownStrip`) only ever
  /// diffs against the device's own clock instead of comparing it to the
  /// server's directly.
  DateTime? _logicSaleLocalDeadline(PaywallLogicSaleEntity logicSale) {
    final endAtUtc = logicSale.endAtUtc;
    final nowUtc = logicSale.nowUtc;
    if (endAtUtc == null || nowUtc == null) return null;
    final remaining = endAtUtc.difference(nowUtc);
    if (remaining <= Duration.zero) return null;
    return DateTime.now().toUtc().add(remaining);
  }

  IapProductEntity _defaultSelectedProduct(List<IapProductEntity> products) {
    for (final product in products) {
      if (product.bestDeal) return product;
    }
    return products.first;
  }

  /// Validates a promo code server-side and, if it authorises a SKU swap,
  /// reloads the paywall showing the discounted plans.
  ///
  /// The server decides which SKUs a code unlocks — the client only renders
  /// what it is handed, so a tampered build cannot force a cheaper product.
  Future<void> applyVoucher(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty || state.isValidatingVoucher) return;

    emit(state.copyWith(isValidatingVoucher: true, hasVoucherFeedback: false));

    final result = await _validateVoucherUsecase.call(ValidateVoucherParams(code: code, platform: PaymentPlatform.fromDevicePlatform)).run();

    final validation = result.match(
      (_) => const VoucherValidationEntity(),
      (value) => value,
    );

    if (!validation.isUsable) {
      emit(
        state.copyWith(
          isValidatingVoucher: false,
          hasVoucherFeedback: true,
          voucherRejectReason: validation.reason,
          // `not_better` means the affiliate DID recognise the code, it just
          // does not beat the sale already running. No SKU swap happens and the
          // user keeps the better price, but the referral is still theirs, so
          // hold the code for verify to report. Every other reason detaches it.
          attributedVoucherCode: validation.reason == VoucherRejectReason.notBetter ? code : '',
        ),
      );
      return;
    }

    // Snapshot, so a failed reload can be rolled back instead of leaving the
    // user on an empty paywall.
    final previousProducts = state.iapProducts;
    final previousSelectedId = state.selectedProductId;

    emit(
      state.copyWith(
        isValidatingVoucher: false,
        appliedVoucherCode: validation.code.isEmpty ? code : validation.code,
        attributedVoucherCode: validation.code.isEmpty ? code : validation.code,
        voucherProducts: validation.products,
        hasVoucherFeedback: true,
        voucherRejectReason: VoucherRejectReason.unknown,
      ),
    );

    if (await loadIapProducts(forceRetry: true)) return;

    // The discounted SKUs did not resolve (missing from the store or the
    // product catalogue). Put the original plans back — never show a blank
    // paywall because of a promo code.
    emit(
      state.copyWith(
        appliedVoucherCode: '',
        voucherProducts: const [],
        iapProducts: previousProducts,
        selectedProductId: previousSelectedId,
        status: previousProducts.isEmpty ? MonetizationStatus.failure : MonetizationStatus.success,
        hasVoucherFeedback: true,
        voucherRejectReason: VoucherRejectReason.notApplicable,
      ),
    );
  }

  Future<void> removeVoucher() async {
    if (!state.hasAppliedVoucher) return;
    emit(
      state.copyWith(
        appliedVoucherCode: '',
        // Removing the code is an explicit detach, so attribution goes too --
        // unlike the rollback path below, where the code stayed valid and only
        // the SKU swap failed.
        attributedVoucherCode: '',
        voucherProducts: const [],
        hasVoucherFeedback: false,
        voucherRejectReason: VoucherRejectReason.unknown,
      ),
    );
    await loadIapProducts(forceRetry: true);
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
        _onPurchaseFailure(error: _verifyRefusalMessage ?? l10n.monetization.verificationFailToast);
        return;
      }

      final nextDetail = _dequeuePendingReceipt(transactionId);
      if (nextDetail == null) {
        _markHandled(transactionId);
        _verifyingTransactionIds.remove(transactionId);
        _onPurchaseFailure(error: _verifyRefusalMessage ?? l10n.monetization.verificationFailToast);
        return;
      }

      currentDetail = nextDetail;
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetail, String transactionId) async {
    late VerifyParams params;

    // Attribution only, and only for a purchase actually STARTED from this
    // paywall session — never a restore, and never a passive receipt
    // reconciliation that never went through purchaseProduct() in the first
    // place (state.lastAction would be `none` there).
    final logicSaleId = state.lastAction == PurchaseAction.purchase ? state.logicSaleId : '';

    if (Platform.isIOS) {
      params = VerifyParams(
        platform: PaymentPlatform.apple,
        productId: purchaseDetail.productID,
        packageName: _packageInfoService.packageName,
        storeTransactionId: transactionId,
        voucherCode: state.attributedVoucherCode,
        logicSaleId: logicSaleId,
      );
    } else {
      final verificationData = purchaseDetail.verificationData;
      params = VerifyParams(
        platform: PaymentPlatform.google,
        productId: purchaseDetail.productID,
        packageName: _packageInfoService.packageName,
        storeTransactionId: verificationData.serverVerificationData,
        voucherCode: state.attributedVoucherCode,
        logicSaleId: logicSaleId,
      );
    }

    _verifyRefusalMessage = null;
    // Folded by hand rather than through runUseCase: that helper narrows the
    // failure to `exception.message`, and the one refusal worth explaining is
    // identified by a code in the response body, not by its text.
    final result = await _verifyUsecase.call(params).run();
    return result.fold((exception) {
      _verifyRefusalMessage = _refusalMessage(exception);
      return false;
    }, (_) => true);
  }

  /// The buyer-actionable refusal, or null to keep the generic toast.
  ///
  /// One store account holds one subscription, so paying again from a store
  /// account whose transaction already belongs to a different Meup account is
  /// refused — and until now that surfaced as "Verification failed", which
  /// tells them nothing and reads like we lost their money. Nothing was
  /// charged: the store re-presented the existing transaction.
  ///
  /// Keyed on the server's stable `code`, never on the message text, which is
  /// localised on both sides and reworded freely. Localised here rather than
  /// shown from the response because the API speaks en/vi and the app ships
  /// five languages. Every other failure keeps the generic line — server
  /// messages for those are config faults ("Product not found"), not something
  /// to put in front of a buyer.
  String? _refusalMessage(AppException exception) {
    final data = switch (exception) {
      FromDioException(error: final error) => error.response?.data,
      _ => null,
    };
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is! List) return null;

    final isLinkedElsewhere = errors.any(
      (entry) => entry is Map && entry['code'] == 'TRANSACTION_LINKED_TO_ANOTHER_USER',
    );
    if (!isLinkedElsewhere) return null;

    return l10n.monetization.storeAccountLinkedToOtherToast(
      store: Platform.isIOS ? 'Apple ID' : 'Google',
    );
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
