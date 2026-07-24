part of '../../habit.dart';

@LazySingleton(as: IHabitRepository)
class HabitRepository with RestfulRequestHandlerMixin implements IHabitRepository {
  final HabitApi _api;

  HabitRepository(this._api);

  @override
  TaskEither<AppException, List<HabitEntity>> getHabits({String? skillsetId, String? keypointId}) {
    return callApiWithTransform<List<HabitModel>, List<HabitEntity>>(
      apiCall: () => _api.getHabits(skillsetId, keypointId),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
      // Inline error/empty states already communicate a failed list load — the
      // base auto-toast only surfaced the raw DioException to the user.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, List<UserHabitEntity>> getUserHabits({UserHabitStateEntity? state}) {
    final stateParam = state == null || state == UserHabitStateEntity.unknown ? null : state.name;
    return callApiWithTransform<List<UserHabitModel>, List<UserHabitEntity>>(
      apiCall: () => _api.getUserHabits(stateParam),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, UserHabitSummaryEntity> getUserHabitsSummary() {
    return callApiWithTransform<UserHabitSummaryModel, UserHabitSummaryEntity>(
      apiCall: () => _api.getUserHabitsSummary(),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitSummaryEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, int> getFreeActiveSlots() {
    return callApiWithTransform<dynamic, int>(
      apiCall: () => _api.getHabitConfig(),
      transform: (data) {
        final slots = (data is Map) ? data['freeActiveSlots'] : null;
        return (slots is int && slots >= 1) ? slots : kFreeActiveHabitSlots;
      },
      defaultValue: kFreeActiveHabitSlots,
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, UserHabitEntity> adoptHabit({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceKeypointId,
    String? sourceCourseId,
    String? reanchorReasonId,
    BaseMultiLanguage? reanchorReason,
  }) {
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.adoptHabit({
        'habitId': habitId,
        if (reminderTime != null) 'reminderTime': reminderTime,
        if (packLength != null) 'packLength': packLength,
        if (sourceKeypointId != null) 'sourceKeypointId': sourceKeypointId,
        if (sourceCourseId != null) 'sourceCourseId': sourceCourseId,
        if (reanchorReasonId != null) 'reanchorReasonId': reanchorReasonId,
        if (reanchorReason != null) 'reanchorReason': reanchorReason.toJson(),
      }),
      transform: (model) => model.toEntity(),
      defaultValue: const UserHabitEntity(),
      // Slot-full (409) is an expected, handled outcome — the caller shows the
      // SlotFullUpgradeSheet and other failures show their own snackbar — so
      // suppress the base handler's auto error toast (it was surfacing the
      // server's "You've filled all your active habit slots" as a red banner
      // on top of the sheet).
      enableErrorMessages: false,
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
      // Activating a paused habit can also hit slot-full (409) — same handled
      // outcome as adopt — so don't show the base auto error toast.
      enableErrorMessages: false,
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

  @override
  TaskEither<AppException, List<ReanchorReasonEntity>> getReanchorReasons(String courseId) {
    return callApiWithTransform<List<ReanchorReasonModel>, List<ReanchorReasonEntity>>(
      apiCall: () => _api.getReanchorReasons(courseId),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }
}
