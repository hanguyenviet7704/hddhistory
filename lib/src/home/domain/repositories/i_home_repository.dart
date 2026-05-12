part of '../../home.dart';

abstract class IHomeRepository {
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest<SkillsetFilterRequest> request,
  );
  TaskEither<AppException, SkillsetEntity> getSkillset(String id);
}
