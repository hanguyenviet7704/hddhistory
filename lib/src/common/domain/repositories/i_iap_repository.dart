part of 'repositories.dart';

abstract interface class IIAPRepository {
  Stream<PurchaseDetails> get purchaseDetailStream;
  TaskEither<AppException, BaseResponseList<IapProduct>> getProducts();
  TaskEither<AppException, BaseResponse<IapVerify>> purchase(PurchaseParams params);
  TaskEither<AppException, BaseResponse<IapVerify>> restore();
  TaskEither<AppException, BaseResponse<IapVerify>> verifyIOSPurchase(VerifyIOSParams params);
  TaskEither<AppException, BaseResponse<IapVerify>> verifyAndroidPurchase(VerifyAndroidParams params);
  void dispose();
}
