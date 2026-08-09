part of '../../monetization.dart';

abstract class IMonetizationRepository {
  Stream<PurchaseDetails> get purchaseDetailStream;
  TaskEither<AppException, List<IapProductEntity>> getProducts(GetPackagesParams params);
  TaskEither<AppException, IapVerifyEntity> purchase(PurchaseParams params);
  TaskEither<AppException, IapVerifyEntity> restore();
  TaskEither<AppException, IapVerifyEntity> verify(VerifyParams params);
  TaskEither<AppException, VoucherValidationEntity> validateVoucher(ValidateVoucherParams params);

  /// Resolves through: live API -> last cached API response -> Left (caller
  /// falls further to Remote Config -> bundled defaults; see
  /// [IapCubit.resolvedPaywallConfig]). Never shows a network error toast —
  /// a failed background refresh must stay silent.
  TaskEither<AppException, PaywallConfigEntity> getPaywallConfig();
  Future<List<String>> loadProcessedTransactionIds();
  Future<void> cacheProcessedTransactionIds(List<String> ids);
  void dispose();
}
