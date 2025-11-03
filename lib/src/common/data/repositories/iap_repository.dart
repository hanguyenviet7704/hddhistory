part of 'repositories.dart';

@LazySingleton(as: IIAPRepository)
class IAPRepository with RestfulRequestHandlerMixin implements IIAPRepository {
  final IAPApi _iapApi;
  final IIapService _iapService;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final StreamController<PurchaseDetails> _purchaseDetailController = StreamController<PurchaseDetails>.broadcast();

  IAPRepository(this._iapApi, this._iapService) {
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
  TaskEither<AppException, BaseResponseList<IapProduct>> getProducts() {
    return callApiList(
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

        final Set<String> productIds = {'artlexis_sub_weekly', 'artlexis_sub_monthly'};
        List<ProductDetails> productDetails = await _iapService.getProducts(productIds: productIds);
        productDetails.sort((a, b) => a.price.compareTo(b.price));
        List<IapProduct> products = productDetails.toIapProducts();

        return BaseResponseList(
          data: products,
          code: 200,
          message: 'Success',
        );
      },
    );
  }

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> purchase(PurchaseParams params) {
    return TaskEither.tryCatch(
      () async {
        bool isSuccess = await _iapService.purchaseProduct(params.productId, params.type);

        if (!isSuccess) return BaseResponse(data: IapVerify(status: 'fail'));
        return BaseResponse(data: IapVerify(status: 'success'));
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> restore() {
    return TaskEither.tryCatch(
      () async {
        await _iapService.restorePurchases();
        return BaseResponse(data: IapVerify(status: 'success'));
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> verifyIOSPurchase(VerifyIOSParams params) {
    // return callApi(
    //   apiCall: () => _iapApi.verifyIos({
    //     'receiptData': params.receiptData,
    //     'useSandbox': params.isSandbox,
    //     'excludeOldTransactions': false,
    //     'useLatestReceiptInfo': true,
    //   }),
    // );
    return callApi(
      apiCall: () => _iapApi.verifyIosV111({
        'transactionId': params.transactionId,
        'receiptData': params.receiptData,
        'useSandbox': params.isSandbox,
      }),
    );
    // return Future.value(Right(BaseResponse(data: IapVerify(status: 'success'))));
  }

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> verifyAndroidPurchase(VerifyAndroidParams params) {
    return callApi(
      apiCall: () => _iapApi.verifyAndroid({
        'productId': params.productId,
        'purchaseToken': params.receiptData,
        'packageName': 'com.eup.meup',
      }),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
  }
}
