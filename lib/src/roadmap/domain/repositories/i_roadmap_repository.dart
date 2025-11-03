part of '../../roadmap.dart';

abstract class IRoadmapRepository {
  TaskEither<AppException, BasePageBreak<RoadmapEntity>> getAllRoadmaps(
    PageBreakRequest request,
  );
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id);
  TaskEither<AppException, RoadmapEntity> createRoadmap(RoadmapEntity entity);
  TaskEither<AppException, RoadmapEntity> updateRoadmap(RoadmapEntity entity);
  TaskEither<AppException, Unit> deleteRoadmap(String id);
}
