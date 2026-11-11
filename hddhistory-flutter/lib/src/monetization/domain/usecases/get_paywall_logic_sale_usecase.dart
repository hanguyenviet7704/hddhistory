part of '../../monetization.dart';

@lazySingleton
class GetPaywallLogicSaleUsecase implements BaseUseCase<Unit, PaywallLogicSaleEntity> {
  final IMonetizationRepository _repository;

  GetPaywallLogicSaleUsecase(this._repository);

  @override
  TaskEither<AppException, PaywallLogicSaleEntity> call(Unit params) => _repository.getLogicSale();
}
