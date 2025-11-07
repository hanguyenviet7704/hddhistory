part of '../../roleplay.dart';

abstract class IRoleplayRepository {
  TaskEither<AppException, BasePageBreak<SectionEntity>> getAllSections(
    PageBreakRequest request,
  );
  TaskEither<AppException, SectionEntity> getSection(String id);
  TaskEither<AppException, SectionEntity> createSection(SectionEntity entity);
  TaskEither<AppException, SectionEntity> updateSection(SectionEntity entity);
  TaskEither<AppException, Unit> deleteSection(String id);
}
