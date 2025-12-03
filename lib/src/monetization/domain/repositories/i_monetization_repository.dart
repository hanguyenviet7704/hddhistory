part of '../../monetization.dart';

abstract class IMonetizationRepository {
  Stream<PurchaseDetails> get purchaseDetailStream;
  TaskEither<AppException, List<IapProductEntity>> getProducts(GetPackagesParams params);
  TaskEither<AppException, IapVerifyEntity> purchase(PurchaseParams params);
  TaskEither<AppException, IapVerifyEntity> restore();
  TaskEither<AppException, IapVerifyEntity> verify(VerifyParams params);
  void dispose();
}
