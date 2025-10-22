part of '../../exercise.dart';

abstract class IExerciseRepository {
  TaskEither<AppException, BasePageBreak<ExerciseEntity>> getAllExercises(
    PageBreakRequest request,
  );
  TaskEither<AppException, ExerciseEntity> getExercise(String id);
  TaskEither<AppException, ExerciseEntity> createExercise(ExerciseEntity entity);
  TaskEither<AppException, ExerciseEntity> updateExercise(ExerciseEntity entity);
  TaskEither<AppException, Unit> deleteExercise(String id);
}
