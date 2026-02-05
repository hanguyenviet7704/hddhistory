part of '../../home.dart';

abstract class IHomeRepository {
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest request,
  );
  TaskEither<AppException, SkillsetEntity> getSkillset(String id);
}
