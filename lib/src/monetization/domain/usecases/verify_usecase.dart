part of '../../monetization.dart';

class VerifyParams {
  final PaymentPlatform platform;
  final String productId;
  final String purchaseToken;
  final String transactionId;
  final String packageName;
  final bool isSandbox;

  VerifyParams({
    required this.platform,
    this.productId = '',
    this.purchaseToken = '',
    this.transactionId = '',
    this.packageName = '',
    this.isSandbox = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform == PaymentPlatform.apple ? 'apple' : 'google',
      'productId': productId,
      'purchaseToken': purchaseToken,
      'transactionId': transactionId,
      'packageName': packageName,
      'isSandbox': isSandbox,
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
