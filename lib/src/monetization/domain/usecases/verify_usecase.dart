part of '../../monetization.dart';

class VerifyParams {
  final PaymentPlatform platform;
  final String productId;
  final String packageName;
  final String storeTransactionId;

  VerifyParams({
    required this.platform,
    this.productId = '',
    this.packageName = '',
    this.storeTransactionId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.name,
      'productId': productId,
      'packageName': packageName,
      'storeTransactionId': storeTransactionId,
    };
  }
}

@lazySingleton
class VerifyUsecase implements UseCaseWithParams<VerifyParams, IapVerifyEntity> {
  final IMonetizationRepository _repository;

  VerifyUsecase(this._repository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(VerifyParams params) => _repository.verify(params);
}
