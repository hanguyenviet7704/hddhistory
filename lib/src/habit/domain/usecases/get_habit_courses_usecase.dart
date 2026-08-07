part of '../../habit.dart';

@lazySingleton
class GetHabitCoursesUseCase {
  final IHabitRepository _repository;

  GetHabitCoursesUseCase(this._repository);

  TaskEither<AppException, List<HabitCourseEntity>> call(String habitId) =>
      _repository.getHabitCourses(habitId);
}
