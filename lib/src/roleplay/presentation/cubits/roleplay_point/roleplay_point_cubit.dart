part of '../../../roleplay.dart';

@lazySingleton
class RoleplayPointCubit extends Cubit<RoleplayPointState> {
  RoleplayPointCubit() : super(RoleplayPointState.initial());

  void reset() => emit(RoleplayPointState.initial());

  void setPoint(KeypointEntity point) {
    List<KeypointEntity> points = List<KeypointEntity>.from(state.points);
    if (points.isEmpty) {
      LogDev.one('RoleplayPointCubit: before empty setPoint: ${point.title}: ${0}');
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.one('RoleplayPointCubit: after empty setPoint: ${point.title}: ${point.point}');
      return;
    }

    // Check if the point already exists
    int index = points.indexWhere((p) => p.id == point.id);
    if (index == -1) {
      LogDev.one('RoleplayPointCubit: before new setPoint: ${point.title}: ${0}');
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.one('RoleplayPointCubit: after new setPoint: ${point.title}: ${point.point}');
      return;
    }
    KeypointEntity existingPoint = points[index];
    LogDev.one('RoleplayPointCubit: before existing setPoint: ${point.title}: ${existingPoint.point}');
    existingPoint = existingPoint.copyWith(point: existingPoint.point + point.point);
    points[index] = existingPoint;
    emit(state.copyWith(points: points));
    LogDev.one('RoleplayPointCubit: after existing setPoint: ${point.title}: ${existingPoint.point}');
  }

  void finishRoleplayLesson() {
    List<KeypointEntity> points = List<KeypointEntity>.from(state.points);
    List<UpdateUserProgressKeypointData> keypoints = points
        .map(
          (point) => UpdateUserProgressKeypointData(
            keypointId: point.id,
            averageScore: point.point.toDouble(),
            passed: true,
            reviews: '',
          ),
        )
        .toList();

    UpdateUserProgressKeypointParams keypointParams = UpdateUserProgressKeypointParams(
      keypoints: keypoints,
    );

    AppDI.injector.get<ProgressCubit>().updateUserProgressKeypoint(LessonType.roleplay, keypointParams);
  }
}
