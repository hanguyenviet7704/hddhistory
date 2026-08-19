part of '../../monetization.dart';

class VerifyParams {
  final PaymentPlatform platform;
  final String productId;
  final String packageName;
  final String storeTransactionId;

  /// Promo code the user had applied when they bought. The server re-validates
  /// it before recording — a stale code must never fail the purchase.
  final String voucherCode;

  /// Attribution only — the server never lets this change the outcome. Set
  /// only for a purchase started from this paywall session while its
  /// LogicSale override was active; a restore never carries it (see
  /// IapCubit._verifyPurchase).
  final String logicSaleId;

  /// Attribution only, same contract as [logicSaleId]: the body A/B run and
  /// the arm this buyer was assigned, sent only when the server actually put
  /// them IN the run (see IapCubit._verifyPurchase). Excluded viewers send
  /// nothing rather than a third value, so neither arm is inflated.
  final String paywallExperimentKey;
  final String paywallBodyVariant;

  VerifyParams({
    required this.platform,
    this.productId = '',
    this.packageName = '',
    this.storeTransactionId = '',
    this.voucherCode = '',
    this.logicSaleId = '',
    this.paywallExperimentKey = '',
    this.paywallBodyVariant = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.name,
      'productId': productId,
      'packageName': packageName,
      'storeTransactionId': storeTransactionId,
      if (voucherCode.isNotEmpty) 'voucherCode': voucherCode,
      if (logicSaleId.isNotEmpty) 'logicSaleId': logicSaleId,
      // Both halves or neither: an arm without its run key cannot be read back.
      if (paywallExperimentKey.isNotEmpty && paywallBodyVariant.isNotEmpty) ...{
        'paywallExperimentKey': paywallExperimentKey,
        'paywallBodyVariant': paywallBodyVariant,
      },
    };
  }
}

@lazySingleton
class VerifyUsecase implements BaseUseCase<VerifyParams, IapVerifyEntity> {
  final IMonetizationRepository _repository;

  VerifyUsecase(this._repository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(VerifyParams params) => _repository.verify(params);
}
