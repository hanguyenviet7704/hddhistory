part of '../../home.dart';

@lazySingleton
class GetRandomQuoteUseCase {
  final IHomeRepository _repository;

  GetRandomQuoteUseCase(this._repository);

  TaskEither<AppException, QuoteEntity> call() => _repository.getRandomQuote();
}
