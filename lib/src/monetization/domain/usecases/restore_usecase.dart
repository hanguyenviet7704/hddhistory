part of '../../monetization.dart';

@lazySingleton
class RestoreUsecase implements UseCaseWithoutParams<IapVerifyEntity> {
  final IMonetizationRepository _iapRepository;

  RestoreUsecase(this._iapRepository);

  @override
  TaskEither<AppException, IapVerifyEntity> call()  => _iapRepository.restore();
}
