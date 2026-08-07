part of '../../habit.dart';

@LazySingleton(as: IHabitRepository)
class HabitRepository with RestfulRequestHandlerMixin implements IHabitRepository {
  final HabitApi _api;
  final HabitLocalDataSource _localDataSource;

  HabitRepository(this._api, this._localDataSource);

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
  TaskEither<AppException, HabitScreenEntity> getHabitScreen({UserHabitStateEntity? state}) {
    final stateParam = state == null || state == UserHabitStateEntity.unknown ? null : state.name;
    return callApiWithTransform<HabitScreenModel, HabitScreenEntity>(
      apiCall: () => _api.getHabitScreen(stateParam),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) await _localDataSource.cacheHabitScreen(data);
      },
      onError: () async {
        final cached = await _localDataSource.getCachedHabitScreen();
        return cached?.toEntity();
      },
      defaultValue: const HabitScreenEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  Future<HabitScreenEntity?> getCachedHabitScreen() async {
    final cached = await _localDataSource.getCachedHabitScreen();
    return cached?.toEntity();
  }

  @override
  TaskEither<AppException, UserHabitEntity> adoptHabit({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceKeypointId,
    String? sourceCourseId,
  }) {
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.adoptHabit({
        'habitId': habitId,
        if (reminderTime != null) 'reminderTime': reminderTime,
        if (packLength != null) 'packLength': packLength,
        if (sourceKeypointId != null) 'sourceKeypointId': sourceKeypointId,
        if (sourceCourseId != null) 'sourceCourseId': sourceCourseId,
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
    HabitCheckinMethodEntity? method,
    int? mood,
    int? score,
  }) {
    final methodValue = method?.apiValue;
    return callApiWithTransform<UserHabitModel, UserHabitEntity>(
      apiCall: () => _api.checkIn(id, {
        'done': done,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (methodValue != null) 'method': methodValue,
        // The API validates mood as 1..3, so a 0 from a bad caller would 400.
        // Dropping it here keeps a UI bug from failing the whole check-in.
        if (mood != null && mood > 0) 'mood': mood,
        if (score != null) 'score': score,
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
  TaskEither<AppException, List<HabitCourseEntity>> getHabitCourses(String habitId) {
    return callApiWithTransform<List<HabitCourseModel>, List<HabitCourseEntity>>(
      apiCall: () => _api.getHabitCourses(habitId),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, List<HabitPracticeEntity>> getHabitPractices(String habitId) {
    return callApiWithTransform<List<HabitPracticeModel>, List<HabitPracticeEntity>>(
      apiCall: () => _api.getHabitPractices(habitId),
      transform: (models) => models.map((model) => model.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, UserHabitEntity> submitPracticeAttempt({
    required String userHabitId,
    required HabitCheckinMethodEntity method,
    String? learningItemId,
    List<Map<String, dynamic>>? exercisesResult,
    int? score,
    int? total,
    int? mood,
    String? note,
  }) {
    final methodValue = method.apiValue;
    return callApiWithTransform<HabitPracticeAttemptResultModel, UserHabitEntity>(
      apiCall: () => _api.submitPracticeAttempt({
        'userHabitId': userHabitId,
        if (methodValue != null) 'method': methodValue,
        if (learningItemId != null && learningItemId.isNotEmpty) 'learningItemId': learningItemId,
        if (exercisesResult != null && exercisesResult.isNotEmpty) 'exercisesResult': exercisesResult,
        if (score != null) 'score': score,
        if (total != null) 'total': total,
        // The API validates mood as 1..3; dropping a 0 keeps a UI bug from
        // failing the whole submission.
        if (mood != null && mood > 0) 'mood': mood,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      }),
      transform: (model) => model.userHabit?.toEntity() ?? const UserHabitEntity(),
      defaultValue: const UserHabitEntity(),
    );
  }
}
