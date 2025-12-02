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
  TaskEither<AppException, List<IapProductEntity>> getProducts() {
    return callApiListWithTransform(
      apiCall: () async {
        // final response = await _iapApi.getPackages();

        // Get products from IAP service
        // await _iapService.getProducts(
        //   productIds: Set.from(response.data.map((e) => e.productId)),
        //   // productIds: {
        //   //   'com.example.app.subscription',
        //   //   'com.example.app.non_consumable',
        //   // },
        // );

        // return response;

        final Set<String> productIds = {'meup_sub_3m', 'meup_sub_1y', 'meup_iap_lifetime'};
        List<ProductDetails> productDetails = await _iapService.getProducts(productIds: productIds);
        productDetails.sort((a, b) => a.price.compareTo(b.price));
        List<IapProductModel> products = productDetails.toIapProducts();

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

        if (!isSuccess) return IapVerifyModel(status: 'fail').toEntity();
        return IapVerifyModel(status: 'success').toEntity();
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
        return IapVerifyModel(status: 'success').toEntity();
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, IapVerifyEntity> verifyIOSPurchase(VerifyIOSParams params) {
    // return callApi(
    //   apiCall: () => _iapApi.verifyIos({
    //     'receiptData': params.receiptData,
    //     'useSandbox': params.isSandbox,
    //     'excludeOldTransactions': false,
    //     'useLatestReceiptInfo': true,
    //   }),
    // );
    return callApiWithTransform<IapVerifyModel, IapVerifyEntity>(
      apiCall: () => _monetizationApi.verifyIosV111({
        'transactionId': params.transactionId,
        'receiptData': params.receiptData,
        'useSandbox': params.isSandbox,
      }),
      transform: (model) => model.toEntity(),
      defaultValue: IapVerifyEntity(),
    );
    // return Future.value(Right(BaseResponse(data: IapVerify(status: 'success'))));
  }

  @override
  TaskEither<AppException, IapVerifyEntity> verifyAndroidPurchase(VerifyAndroidParams params) {
    return callApiWithTransform<IapVerifyModel, IapVerifyEntity>(
      apiCall: () => _monetizationApi.verifyAndroid({
        'productId': params.productId,
        'purchaseToken': params.receiptData,
        'packageName': 'com.eup.meup',
      }),
      transform: (model) => model.toEntity(),
      defaultValue: IapVerifyEntity(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
  }
}
