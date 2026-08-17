part of '../../library.dart';

@lazySingleton
class GetSavedCardsUseCase {
  final ISavedRepository _repository;

  GetSavedCardsUseCase(this._repository);

  TaskEither<AppException, BasePageBreak<SavedCardEntity>> call({
    required int page,
    required int take,
  }) => _repository.getSavedCards(page: page, take: take);
}
