part of '../../monetization.dart';

@freezed
abstract class GetPackagesParams with _$GetPackagesParams implements JsonRequestConvertible {
  const factory GetPackagesParams({
    @Default(PaymentPlatform.google) PaymentPlatform platform,
  }) = _GetPackagesParams;

  factory GetPackagesParams.fromJson(Map<String, dynamic> json) => _$GetPackagesParamsFromJson(json);
}

@lazySingleton
class GetPackagesUsecase implements UseCaseWithParams<GetPackagesParams, List<IapProductEntity>> {
  final IMonetizationRepository _iapRepository;

  GetPackagesUsecase(this._iapRepository);

  @override
  TaskEither<AppException, List<IapProductEntity>> call(GetPackagesParams params) => _iapRepository.getProducts(params);
}
