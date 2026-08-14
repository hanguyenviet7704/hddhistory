part of '../../monetization.dart';

@LazySingleton(as: IMonetizationRepository)
class MonetizationRepository with RestfulRequestHandlerMixin implements IMonetizationRepository {
  final MonetizationApi _monetizationApi;
  final IIapService _iapService;
  final UserSubscriptionLocalDataSource _userSubscriptionLocalDataSource;
  final PaywallConfigApi _paywallConfigApi;
  final PaywallConfigLocalDataSource _paywallConfigLocalDataSource;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final StreamController<PurchaseDetails> _purchaseDetailController = StreamController<PurchaseDetails>.broadcast();

  MonetizationRepository(
    this._monetizationApi,
    this._iapService,
    this._userSubscriptionLocalDataSource,
    this._paywallConfigApi,
    this._paywallConfigLocalDataSource,
  ) {
    _setupSubscription();
  }

  @override
  Stream<PurchaseDetails> get purchaseDetailStream => _purchaseDetailController.stream;

  void _setupSubscription() {
    _subscription = _iapService.purchaseStream.listen(
      _onData,
      onDone: () {
        _subscription.cancel();
        LogDev.info('Purchase stream done');
      },
      onError: (error) {
        _subscription.cancel();
        LogDev.error('Purchase stream error: $error');
      },
      // cancelOnError: true,
    );
  }

  void _onData(List<PurchaseDetails> purchaseDetails) {
    for (var purchaseDetail in purchaseDetails) {
      _purchaseDetailController.add(purchaseDetail);
    }
    LogDev.info('Purchase details: ${purchaseDetails.map((e) => e.toJsonString).join(', ')}');
  }

  @override
  TaskEither<AppException, List<IapProductEntity>> getProducts(GetPackagesParams params) {
    return TaskEither.tryCatch(
      () async {
        final selectedIds = _validatedSelectedProductIds(params.selectedProductIds);
        final remoteProducts = await _loadSelectedRemoteProducts(params, selectedIds);
        final productDetails = await _iapService.getProducts(productIds: _storeIdsToQuery(selectedIds, remoteProducts));
        final storeProducts = productDetails.toIapProducts();
        final products = remoteProducts.mapStoreData(storeProducts);
        if (products.length != selectedIds.length) {
          throw StateError('Configured store product is missing');
        }
        return products.map((product) => product.toEntity()).toList();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  /// The selected SKUs plus every SKU they are priced against, because the
  /// struck-through price on the paywall is the *real* store price of that
  /// other SKU rather than a number typed in admin.
  ///
  /// A compare-at SKU never becomes a purchasable row: `mapStoreData` iterates
  /// the selected products only, so these extra ids are used for their price
  /// and nothing else — and one missing from the store cannot fail the
  /// "configured store product is missing" guard below.
  Set<String> _storeIdsToQuery(List<String> selectedIds, List<IapProductModel> remoteProducts) {
    return <String>{
      ...selectedIds,
      ...remoteProducts.map((product) => product.compareAtProductId.trim()).where((id) => id.isNotEmpty),
    };
  }

  List<String> _validatedSelectedProductIds(List<String> selectedProductIds) {
    final ids = selectedProductIds.map((id) => id.trim()).toList();
    if (ids.isEmpty || ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
      throw ArgumentError('Invalid selected product ids');
    }
    return ids;
  }

  Future<List<IapProductModel>> _loadSelectedRemoteProducts(GetPackagesParams params, List<String> selectedIds) async {
    final selectedSet = selectedIds.toSet();
    final foundByProductId = <String, IapProductModel>{};
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages && foundByProductId.length < selectedIds.length) {
      final response = await _monetizationApi.getPackages(
        PageBreakRequest<GetPackagesParams>(page: page, limit: 10, filter: params),
      );
      final pageData = response.data;
      if (pageData == null) break;
      totalPages = pageData.totalPages <= 0 ? page : pageData.totalPages;
      for (final item in pageData.items) {
        if (selectedSet.contains(item.productId)) {
          foundByProductId[item.productId] = item;
        }
      }
      if (pageData.items.isEmpty || page >= totalPages) break;
      page++;
    }

    if (foundByProductId.length != selectedIds.length) {
      throw StateError('Configured BE product is missing');
    }
    return [for (final id in selectedIds) foundByProductId[id]!];
  }

  @override
  TaskEither<AppException, IapVerifyEntity> purchase(PurchaseParams params) {
    return TaskEither.tryCatch(
      () async {
        bool isSuccess = await _iapService.purchaseProduct(params.productId, params.type);

        if (!isSuccess) return IapVerifyModel(status: IapPurchaseStatus.failed).toEntity();
        return IapVerifyModel(status: IapPurchaseStatus.paid).toEntity();
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, IapVerifyEntity> restore() {
    return TaskEither.tryCatch(
      () async {
        await _iapService.restorePurchases();
        return IapVerifyModel().toEntity();
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, IapVerifyEntity> verify(VerifyParams params) {
    return callApiWithTransform<IapVerifyModel, IapVerifyEntity>(
      apiCall: () => _monetizationApi.verify(params.toJson()),
      transform: (model) => model.toEntity(),
      defaultValue: IapVerifyEntity(),
    );
  }

  @override
  TaskEither<AppException, VoucherValidationEntity> validateVoucher(ValidateVoucherParams params) {
    return callApiWithTransform<VoucherValidationModel, VoucherValidationEntity>(
      apiCall: () => _monetizationApi.validateVoucher(params.toJson()),
      transform: (model) => model.toEntity(),
      defaultValue: const VoucherValidationEntity(),
    );
  }

  /// See [IMonetizationRepository.getPaywallConfig]: a fetch failure with no
  /// cached fallback resolves to `Left` — it never invents an empty entity —
  /// so the caller (IapCubit) knows to keep serving Remote Config / bundled
  /// defaults instead of overwriting a good in-memory value with a blank one.
  @override
  TaskEither<AppException, PaywallConfigEntity> getPaywallConfig() {
    return callApiWithTransform<dynamic, PaywallConfigEntity>(
      apiCall: () => _paywallConfigApi.getPaywallConfig(),
      transform: (data) => PaywallConfigEntity.fromRawConfig(jsonEncode(data)),
      onSuccess: (data) async {
        if (data is Map<String, dynamic>) {
          await _paywallConfigLocalDataSource.cacheConfig(data);
        }
      },
      onError: () async {
        final cached = await _paywallConfigLocalDataSource.getCachedConfig();
        if (cached == null) return null;
        return PaywallConfigEntity.fromRawConfig(jsonEncode(cached));
      },
      enableErrorMessages: false,
    );
  }

  /// Never falls back to a cache — a stale LogicSale (wrong SKUs, wrong
  /// deadline) is worse than showing none, unlike [getPaywallConfig] where a
  /// stale value still beats Remote Config's coarser defaults.
  @override
  TaskEither<AppException, PaywallLogicSaleEntity> getLogicSale() {
    return callApiWithTransform<PaywallLogicSaleModel, PaywallLogicSaleEntity>(
      apiCall: () => _paywallConfigApi.getLogicSale(),
      transform: (model) => model.toEntity(),
      defaultValue: const PaywallLogicSaleEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  Future<List<String>> loadProcessedTransactionIds() async {
    try {
      final data = await _userSubscriptionLocalDataSource.getProcessedTransactionIds();
      return data;
    } catch (e) {
      LogDev.warning('Failed to load processed transaction ids: $e');
      return [];
    }
  }

  @override
  Future<void> cacheProcessedTransactionIds(List<String> ids) async {
    try {
      await _userSubscriptionLocalDataSource.cacheProcessedTransactionIds(ids);
    } catch (e) {
      LogDev.warning('Failed to cache processed transaction ids: $e');
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
  }
}
