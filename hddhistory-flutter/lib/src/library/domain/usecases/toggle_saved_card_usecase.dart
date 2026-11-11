part of '../../library.dart';

@lazySingleton
class ToggleSavedCardUseCase {
  final ISavedRepository _repository;

  ToggleSavedCardUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required SaveCardParams params,
    required bool save,
  }) => save ? _repository.saveCard(params) : _repository.unsaveCard(params.keypointId);
}
