part of '../../../profile.dart';

@lazySingleton
class ProfileCubit extends HydratedCubit<ProfileState> with CubitUseCaseHandlerMixin<ProfileState> {
  final GetUserUseCase _getUseCase;
  final UpdateUserUseCase _updateUseCase;
  final GetUserIapSubscriptionsUseCase _getUserIapSubscriptionsUseCase;

  Future<void>? _ensureInFlight;

  ProfileCubit(
    this._getUseCase,
    this._updateUseCase,
    this._getUserIapSubscriptionsUseCase,
  ) : super(ProfileState.initial());

  @override
  ProfileState fromJson(Map<String, dynamic> json) => normalizeHydratedProfileState(ProfileState.fromJson(json));

  @override
  Map<String, dynamic> toJson(ProfileState state) => state.toJson();

  void reset() {
    _ensureInFlight = null;
    emit(ProfileState.initial());
  }

  void setUser(UserEntity user) => emit(state.copyWith(user: user));

  /// Self-heal for the Profile page: fetches when the user identity is blank
  /// (an earlier loadUser() failed or never ran — e.g. it lost the race
  /// against skillsets inside HomeCubit's Future.wait) or the last load
  /// failed. No-op when data is present or a load is already running, so
  /// it's safe to call on every page mount and tab return. Mirrors
  /// [CourseRoadmapCubit.ensureRoadmapLoaded]. Without this, a failed or
  /// skipped first load leaves ProfilePage's identity/premium banner blank
  /// until the user pull-to-refreshes or restarts the app.
  Future<void> ensureProfileLoaded() {
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;
    if (!shouldEnsureProfileReload(state)) return Future.value();
    final future = loadUser().whenComplete(() => _ensureInFlight = null);
    _ensureInFlight = future;
    return future;
  }

  Future<void> loadUser({bool isInit = false}) async {
    if (state.user.id.isEmpty) return;
    await runUseCase<UserEntity>(
      usecase: () => _getUseCase(state.user.id),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProfileStatus.success, user: item));
        loadUserIapSubscriptions();
      },
    );
  }

  Future<void> loadUserIapSubscriptions() async {
    if (state.user.id.isEmpty) return;
    await runUseCase<IapSubscriptionEntity>(
      usecase: () => _getUserIapSubscriptionsUseCase(state.user.id),
      onSuccess: (items) {
        if (items.id.isEmpty) {
          UserEntity user = state.user.copyWith(iapSubscriptions: []);
          emit(state.copyWith(user: user));
          return;
        }
        UserEntity user = state.user.copyWith(iapSubscriptions: [items]);
        emit(state.copyWith(user: user));
      },
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
    );
  }

  void updateUser(UserEntity entity) async {
    if (entity.id.isEmpty) return;
    if (entity.name == state.user.name) return;

    Map<String, dynamic> params = {
      'id': entity.id,
      'name': entity.name,
    };

    await runUseCase<UserEntity>(
      usecase: () => _updateUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (updatedItem) {
        emit(state.copyWith(status: ProfileStatus.success));
        loadUser();
      },
    );
  }
}
