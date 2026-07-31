part of '../../monetization.dart';

class ValidateVoucherParams {
  final String code;
  final PaymentPlatform platform;

  ValidateVoucherParams({
    required this.code,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code.trim().toUpperCase(),
      'platform': platform.name,
    };
  }
}

@lazySingleton
class ValidateVoucherUsecase implements BaseUseCase<ValidateVoucherParams, VoucherValidationEntity> {
  final IMonetizationRepository _repository;

  ValidateVoucherUsecase(this._repository);

  @override
  TaskEither<AppException, VoucherValidationEntity> call(ValidateVoucherParams params) =>
      _repository.validateVoucher(params);
}
