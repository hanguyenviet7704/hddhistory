part of '../../../roleplay.dart';

@lazySingleton
class RoleplayPointCubit extends Cubit<RoleplayPointState> {
  RoleplayPointCubit() : super(RoleplayPointState.initial());

  void reset() => emit(RoleplayPointState.initial());

  void setPoint(RoleplayPointEntity point) {
    LogDev.info('RoleplayPointCubit: before setPoint: ${point.keypoint.id} - ${point.point}');
    List<RoleplayPointEntity> points = List<RoleplayPointEntity>.from(state.points);
    if (points.isEmpty) {
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.info('RoleplayPointCubit: after setPoint: ${point.keypoint.id} - ${point.point}');
      return;
    }

    // Check if the point already exists
    int index = points.indexWhere((p) => p.keypoint.id == point.keypoint.id);
    if (index == -1) {
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.info('RoleplayPointCubit: after setPoint: ${point.keypoint.id} - ${point.point}');
      return;
    }
    RoleplayPointEntity existingPoint = points[index];
    existingPoint = existingPoint.copyWith(point: existingPoint.point + point.point);
    points[index] = existingPoint;
    emit(state.copyWith(points: points));
    LogDev.info('RoleplayPointCubit: after setPoint: ${point.keypoint.id} - ${point.point}');
  }
}
