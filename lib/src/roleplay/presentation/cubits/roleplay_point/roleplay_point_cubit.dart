part of '../../../roleplay.dart';

@lazySingleton
class RoleplayPointCubit extends Cubit<RoleplayPointState> {
  RoleplayPointCubit() : super(RoleplayPointState.initial());

  void reset() => emit(RoleplayPointState.initial());

  void setPoint(KeypointEntity point) {
    LogDev.info('RoleplayPointCubit: before setPoint: ${point.id} - ${point.point}');
    List<KeypointEntity> points = List<KeypointEntity>.from(state.points);
    if (points.isEmpty) {
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.info('RoleplayPointCubit: after setPoint: ${point.id} - ${point.point}');
      return;
    }

    // Check if the point already exists
    int index = points.indexWhere((p) => p.id == point.id);
    if (index == -1) {
      points.add(point);
      emit(state.copyWith(points: points));
      LogDev.info('RoleplayPointCubit: after setPoint: ${point.id} - ${point.point}');
      return;
    }
    KeypointEntity existingPoint = points[index];
    existingPoint = existingPoint.copyWith(point: existingPoint.point + point.point);
    points[index] = existingPoint;
    emit(state.copyWith(points: points));
    LogDev.info('RoleplayPointCubit: after setPoint: ${point.id} - ${point.point}');
  }
}
