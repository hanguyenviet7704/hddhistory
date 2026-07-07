part of '../../habit.dart';

@lazySingleton
class GetReanchorReasonsUseCase {
  final IHabitRepository _repository;

  GetReanchorReasonsUseCase(this._repository);

  TaskEither<AppException, List<ReanchorReasonEntity>> call(String courseId) => _repository.getReanchorReasons(courseId);
}
