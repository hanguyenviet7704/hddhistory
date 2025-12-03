part of '../../monetization.dart';

class VerifyParams {
  final PaymentPlatform platform;
  final String productId;
  final String packageName;
  final String storeTransactionId;
  final String subscriptionId;
  final String originalTransactionId;

  VerifyParams({
    required this.platform,
    this.productId = '',
    this.packageName = '',
    this.storeTransactionId = '',
    this.subscriptionId = '',
    this.originalTransactionId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform == PaymentPlatform.apple ? 'apple' : 'google',
      'productId': productId,
      'packageName': packageName,
      'storeTransactionId': storeTransactionId,
      'subscriptionId': subscriptionId,
      'originalTransactionId': originalTransactionId,
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
