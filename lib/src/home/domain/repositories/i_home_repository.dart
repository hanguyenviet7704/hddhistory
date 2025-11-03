part of '../../home.dart';

abstract class IHomeRepository {
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest request,
  );
  TaskEither<AppException, SkillsetEntity> getSkillset(String id);
  TaskEither<AppException, SkillsetEntity> createSkillset(SkillsetEntity entity);
  TaskEither<AppException, SkillsetEntity> updateSkillset(SkillsetEntity entity);
  TaskEither<AppException, Unit> deleteSkillset(String id);
}
