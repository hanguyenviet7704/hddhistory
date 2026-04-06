part of '../../video_lesson.dart';

@lazySingleton
class GetVideoLearningItemUseCase implements BaseUseCase<String, LearningItemEntity> {
  final IVideoLessonRepository _repository;

  GetVideoLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(String params) {
    return _repository.getLearningItem(params);
  }
}
