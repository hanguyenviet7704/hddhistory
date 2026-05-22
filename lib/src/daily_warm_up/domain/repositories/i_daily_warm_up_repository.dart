part of '../../daily_warm_up.dart';

abstract class IDailyWarmUpRepository {
  TaskEither<AppException, DailyWarmUpEntity> getDailyWarmUp(String id);
  
}

