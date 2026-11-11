part of '../../monetization.dart';

@lazySingleton
class RestoreUsecase implements BaseUseCase<Unit, IapVerifyEntity> {
  final IMonetizationRepository _iapRepository;

  RestoreUsecase(this._iapRepository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(Unit _) => _iapRepository.restore();
}
