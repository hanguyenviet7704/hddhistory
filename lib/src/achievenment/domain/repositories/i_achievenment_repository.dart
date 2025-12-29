part of '../../achievenment.dart';

abstract class IAchievenmentRepository {
  TaskEither<AppException, AchievenmentResponseEntity> getAchievenmentResponse(String id);
  
}

