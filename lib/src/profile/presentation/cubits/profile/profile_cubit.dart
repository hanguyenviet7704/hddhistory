part of '../../../profile.dart';

@lazySingleton
class ProfileCubit extends HydratedCubit<ProfileState> with CubitUseCaseHandlerMixin<ProfileState> {
  final GetUserUseCase _getUseCase;
  final UpdateUserUseCase _updateUseCase;
  final GetUserIapSubscriptionsUseCase _getUserIapSubscriptionsUseCase;
  final UploadCubit _uploadCubit;

  Future<void>? _ensureInFlight;

  ProfileCubit(
    this._getUseCase,
    this._updateUseCase,
    this._getUserIapSubscriptionsUseCase,
    this._uploadCubit,
  ) : super(ProfileState.initial());

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'ProfileCubit';

  @override
  ProfileState fromJson(Map<String, dynamic> json) => normalizeHydratedProfileState(ProfileState.fromJson(json));

  @override
  Map<String, dynamic> toJson(ProfileState state) => state.toJson();

  void reset() {
    _ensureInFlight = null;
    emit(ProfileState.initial());
  }

  void setUser(UserEntity user) => emit(state.copyWith(user: user));

  /// Self-heal for the Profile page: refetches when the last load FAILED
  /// (e.g. it lost the race against skillsets inside HomeCubit's
  /// Future.wait), and recovers a blank identity by seeding it from
  /// [UserCubit] — the auth-side source of truth, populated by setAuth and
  /// hydrated independently — because [loadUser] is id-parameterized and
  /// early-returns on a blank id. No-op when data is present, a load is
  /// already running, or neither cubit knows the user yet, so it's safe to
  /// call on every page mount and tab return. Mirrors
  /// [CourseRoadmapCubit.ensureRoadmapLoaded]. Without this, a failed or
  /// skipped first load leaves ProfilePage's identity/premium banner blank
  /// until the user pull-to-refreshes or restarts the app.
  Future<void> ensureProfileLoaded() {
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;
    if (!shouldEnsureProfileReload(state)) return Future.value();
    if (state.user.id.isEmpty) {
      final authUser = AppDI.injector.get<UserCubit>().state.user;
      if (authUser.id.isEmpty) return Future.value();
      setUser(authUser);
    }
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
        // Self-heal the onboarding flag from the server's answer: a restored
        // session (reinstall) may carry a Keychain blob written BEFORE the
        // user finished onboarding, whose stale `isOnboarded: false` re-ran
        // onboarding for guests. The fresh /users/me is the truth.
        if (item.isOnboarded) {
          final userCubit = AppDI.injector.get<UserCubit>();
          if (userCubit.state.isUserPassOnboarding) {
            userCubit.setIsUserPassOnboarding(false);
          }
        }
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

    // Only the fields that actually changed go in the payload — the endpoint
    // is a partial update, and sending an unchanged name alongside a new
    // avatar (or vice versa) buys nothing.
    final Map<String, dynamic> params = {'id': entity.id};
    if (entity.name != state.user.name) params['name'] = entity.name;
    if (entity.avatar != state.user.avatar) params['avatar'] = entity.avatar;
    if (params.length == 1) return;

    await runUseCase<UserEntity>(
      usecase: () => _updateUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (updatedItem) {
        emit(state.copyWith(status: ProfileStatus.success));
        // UserCubit holds an independently-hydrated copy of this identity
        // (state.auth.user); mirror the edit or it reverts there after a
        // restart. Same seeding relationship as [ensureProfileLoaded].
        AppDI.injector.get<UserCubit>().applyProfileEdit(
              name: params['name'] as String?,
              avatar: params['avatar'] as String?,
            );
        loadUser();
      },
    );
  }

  /// Change the avatar: upload the picked image, then save its URL on the
  /// account through the ordinary [updateUser] path.
  ///
  /// One user action, two requests. The object key is unique per upload on
  /// purpose: avatars render through URL-keyed image caches, so overwriting a
  /// fixed per-user key would keep serving the stale picture everywhere the
  /// old URL is already cached.
  Future<void> updateAvatar(File file) async {
    final user = state.user;
    if (user.id.isEmpty) return;

    emit(state.copyWith(status: ProfileStatus.loading));

    final String name = file.path.split('/').last;
    final String ext = name.contains('.') ? name.split('.').last : 'jpg';
    _uploadCubit.uploadFile(
      UploadFileParams(
        file: MultipartFile.fromFileSync(file.path),
        key: 'user_avatar/${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext',
        prefix: '',
        folder: '',
      ),
      onSuccess: (result) => updateUser(user.copyWith(avatar: result.url)),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
    );
  }
}
