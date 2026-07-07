part of '../../habit.dart';

@LazySingleton(as: IHabitRepository)
class HabitRepository with RestfulRequestHandlerMixin implements IHabitRepository {
  final HabitApi _api;

  HabitRepository(this._api);

  @override
  TaskEither<AppException, List<HabitEntity>> getHabits({String? skillsetId, String? lessonId}) {
    return callApiWithTransform<List<HabitModel>, List<HabitEntity>>(
      apiCall: () => _api.getHabits(skillsetId, lessonId),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, List<UserHabitEntity>> getUserHabits({UserHabitStateEntity? state}) {
    final stateParam = state == null || state == UserHabitStateEntity.unknown ? null : state.name;
    return callApiWithTransform<List<UserHabitModel>, List<UserHabitEntity>>(
      apiCall: () => _api.getUserHabits(stateParam),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, UserHabitSummaryEntity> getUserHabitsSummary() {
    return callApiWithTransform<UserHabitSummaryModel, UserHabitSummaryEntity>(
      apiCall: () => _api.getUserHabitsSummary(),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitSummaryEntity(),
    );
  }

  @override
  TaskEither<AppException, UserHabitEntity> adoptHabit({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceLessonId,
    String? sourceCourseId,
  }) {
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.adoptHabit({
        'habitId': habitId,
        if (reminderTime != null) 'reminderTime': reminderTime,
        if (packLength != null) 'packLength': packLength,
        if (sourceLessonId != null) 'sourceLessonId': sourceLessonId,
        if (sourceCourseId != null) 'sourceCourseId': sourceCourseId,
      }),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitEntity(),
    );
  }

  @override
  TaskEither<AppException, UserHabitEntity> updateUserHabit(
    String id, {
    UserHabitStateEntity? state,
    String? reminderTime,
    int? packLength,
  }) {
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.updateUserHabit(id, {
        if (state != null && state != UserHabitStateEntity.unknown) 'state': state.name,
        if (reminderTime != null) 'reminderTime': reminderTime,
        if (packLength != null) 'packLength': packLength,
      }),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> removeUserHabit(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.removeUserHabit(id);
        return unit;
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, UserHabitEntity> checkIn(
    String id, {
    required bool done,
    DateTime? date,
    String? note,
  }) {
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.checkIn(id, {
        'done': done,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      }),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitEntity(),
    );
  }

  @override
  TaskEither<AppException, List<HabitCheckinEntity>> getCheckins(String id) {
    return callApiWithTransform<List<HabitCheckinModel>, List<HabitCheckinEntity>>(
      apiCall: () => _api.getCheckins(id),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }
}
