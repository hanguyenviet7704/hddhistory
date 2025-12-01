part of '../../monetization.dart';

@lazySingleton
class GetPackagesUsecase implements UseCaseWithoutParams<List<IapProductEntity>> {
  final IMonetizationRepository _iapRepository;

  GetPackagesUsecase(this._iapRepository);

  @override
  TaskEither<AppException, List<IapProductEntity>> call()  => _iapRepository.getProducts();
}
