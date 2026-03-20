part of '../../lesson.dart';

@lazySingleton
class SendScoreRecordUseCase implements BaseUseCase<Map<String, dynamic>, VoiceScoreEntity> {
  final ILessonRepository _repository;

  SendScoreRecordUseCase(this._repository);

  @override
  TaskEither<AppException, VoiceScoreEntity> call(Map<String, dynamic> params) {
    return _repository.sendScoreRecord(params);
  }
}
