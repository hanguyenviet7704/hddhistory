part of '../../monetization.dart';

@LazySingleton(as: IMonetizationRepository)
class MonetizationRepository with RestfulRequestHandlerMixin implements IMonetizationRepository {
  final MonetizationApi _monetizationApi;
  final IIapService _iapService;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final StreamController<PurchaseDetails> _purchaseDetailController = StreamController<PurchaseDetails>.broadcast();

  MonetizationRepository(this._monetizationApi, this._iapService) {
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
    return callApiListWithTransform(
      apiCall: () async {
        final response = await _monetizationApi.getPackages(PageBreakRequest<GetPackagesParams>(page: 1, limit: 10, filter: params));

        final Set<String> productIds = response.data?.items.map((e) => e.productId).toSet() ?? {};
        List<ProductDetails> productDetails = await _iapService.getProducts(productIds: productIds);
        List<IapProductModel> storeProducts = productDetails.toIapProducts();
        List<IapProductModel> remoteProducts = response.data?.items ?? [];
        List<IapProductModel> products = remoteProducts.mapStoreData(storeProducts);
        

        return BaseResponseList(
          data: products,
          code: 200,
          message: 'Success',
        );
      },
      transform: (data) => data.toEntity(),
    );
  }

  @override
  TaskEither<AppException, IapVerifyEntity> purchase(PurchaseParams params) {
    return TaskEither.tryCatch(
      () async {
        bool isSuccess = await _iapService.purchaseProduct(params.productId, params.type);

        if (!isSuccess) return IapVerifyModel(status: PurchaseStatus.error).toEntity();
        return IapVerifyModel(status: PurchaseStatus.purchased).toEntity();
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
  void dispose() {
    _subscription.cancel();
  }
}
