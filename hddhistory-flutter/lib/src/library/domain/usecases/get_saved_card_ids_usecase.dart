part of '../../library.dart';

@lazySingleton
class GetSavedCardIdsUseCase {
  final ISavedRepository _repository;

  GetSavedCardIdsUseCase(this._repository);

  TaskEither<AppException, List<String>> call() => _repository.getSavedCardIds();
}
