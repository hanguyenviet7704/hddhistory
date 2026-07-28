part of '../../monetization.dart';

@lazySingleton
class GetPaywallConfigUsecase implements BaseUseCase<Unit, PaywallConfigEntity> {
  final IMonetizationRepository _repository;

  GetPaywallConfigUsecase(this._repository);

  @override
  TaskEither<AppException, PaywallConfigEntity> call(Unit params) => _repository.getPaywallConfig();
}
