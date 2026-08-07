part of '../../auth.dart';

@lazySingleton
class UserCubit extends HydratedCubit<UserState> with CubitUseCaseHandlerMixin<UserState> {
  UserCubit(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService) : super(UserState.initial()) {
    // _onAutoSignUpGuest();
  }
  // final RegisterUsecase _registerUsecase;
  final BaseTrackingService _appTrackingService;

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'UserCubit';

  @override
  UserState fromJson(Map<String, dynamic> json) => UserState.fromJson(json);

  @override
  Map<String, dynamic> toJson(UserState state) => state.toJson();

  void setIsUserPassOnboarding(bool isUserPassOnboarding) {
    final shouldMarkDailyWarmUpOnboardingDate = state.isUserPassOnboarding && !isUserPassOnboarding;
    emit(state.copyWith(isUserPassOnboarding: isUserPassOnboarding));
    if (shouldMarkDailyWarmUpOnboardingDate) {
      unawaited(_markDailyWarmUpOnboardingCompletedDate());
    }
  }

  /// Records the order the user tapped categories (Path — Feel/Think/Work/
  /// Connect/Learn/Explore Better) during onboarding, so the Explore tab can
  /// show them in that same order instead of the backend's default sort.
  /// Called once, right when onboarding hands off to Home.
  void setOnboardingPathOrder(List<OnboardingPath> order) => emit(state.copyWith(onboardingPathOrder: order));

  void setIsAppEventConfigured(bool isAppEventConfigured) => emit(state.copyWith(isAppEventConfigured: isAppEventConfigured));
  void setIsFirstTimeUserAccessLessonList(bool isFirstTimeUserAccessLessonList) => emit(state.copyWith(isFirstTimeUserAccessLessonList: isFirstTimeUserAccessLessonList));
  void setIsFirstTimeUserChooseCourse(bool isFirstTimeUserChooseCourse) => emit(state.copyWith(isFirstTimeUserChooseCourse: isFirstTimeUserChooseCourse));
  void setIsFirstTimeLessonNavigationGuide(bool isFirstTimeLessonNavigationGuide) => emit(state.copyWith(isFirstTimeLessonNavigationGuide: isFirstTimeLessonNavigationGuide));
  void setHasCompletedFirstTimeNotificationGate(bool hasCompletedFirstTimeNotificationGate) =>
      emit(state.copyWith(hasCompletedFirstTimeNotificationGate: hasCompletedFirstTimeNotificationGate));
  void setHasCompletedCourseEntryNotificationGate(bool hasCompletedCourseEntryNotificationGate) =>
      emit(state.copyWith(hasCompletedCourseEntryNotificationGate: hasCompletedCourseEntryNotificationGate));

  void completeFirstTimeNotificationGate() {
    if (state.hasCompletedFirstTimeNotificationGate) return;
    emit(state.copyWith(hasCompletedFirstTimeNotificationGate: true));
  }

  void completeCourseEntryNotificationGate() {
    if (state.hasCompletedCourseEntryNotificationGate) return;
    emit(state.copyWith(hasCompletedCourseEntryNotificationGate: true));
  }

  void startFirstTimeRegisterFlow() {
    final shouldMarkDailyWarmUpOnboardingDate = state.isUserPassOnboarding;
    emit(
      state.copyWith(
        isUserPassOnboarding: false,
        hasPendingFirstTimePaywallAfterAuth: true,
      ),
    );
    if (shouldMarkDailyWarmUpOnboardingDate) {
      unawaited(_markDailyWarmUpOnboardingCompletedDate());
    }
  }

  void consumeFirstTimePaywallAfterAuthIntent() {
    if (!state.hasPendingFirstTimePaywallAfterAuth) return;
    emit(state.copyWith(hasPendingFirstTimePaywallAfterAuth: false));
  }

  void setAccessToken(String accessToken) {
    AppGlobalValue.accessToken = accessToken;
    TokenEntity token = TokenEntity(accessToken: accessToken, refreshToken: state.refreshToken, expiresAt: DateTime.now().add(Duration(seconds: 30)));
    AuthEntity auth = state.auth.copyWith(token: token);
    emit(state.copyWith(auth: auth));
  }

  void setAuth(AuthEntity auth) {
    final previousUserId = state.user.id;
    final nextUserId = auth.user.id;
    final isUserChanged = previousUserId != nextUserId;

    // Trust the server's onboarded flag: a returning, already-onboarded account
    // must SKIP onboarding after a fresh login (e.g. after a reinstall wiped the
    // local flag), instead of being sent through onboarding again. Never forces
    // onboarding back on (only flips to "passed" when the server confirms it).
    emit(state.copyWith(
      auth: auth,
      isUserPassOnboarding: auth.user.isOnboarded ? false : state.isUserPassOnboarding,
    ));
    if (!state.isUserPassOnboarding && nextUserId.isNotEmpty) {
      unawaited(_markDailyWarmUpOnboardingCompletedDate());
    }

    if (isUserChanged && previousUserId.isNotEmpty) {
      unawaited(_clearLearningStreakCacheForUser(previousUserId));
      if (AppDI.injector.isRegistered<LearningStreakCubit>()) {
        AppDI.injector.get<LearningStreakCubit>().reset();
      }
    }

    AppDI.injector.get<ProfileCubit>()
      ..setUser(auth.user)
      ..loadUser();
    setTrackingUser();
    unawaited(_persistAuthSession(auth));
  }

  /// Mirrors the session into secure storage — see [LocalStoreKey.authSession].
  ///
  /// Fire-and-forget on purpose: a write that fails must not hold up sign-in.
  /// The worst case is the reader signing in again after a reinstall, which is
  /// exactly where they were before this existed.
  Future<void> _persistAuthSession(AuthEntity auth) async {
    if (auth.token.refreshToken.isEmpty) return;
    try {
      await AppDI.injector.get<ILocalStoreService>().setMap(
            key: LocalStoreKey.authSession,
            value: auth.toJson(),
          );
    } catch (error) {
      LogDev.warning('[UserCubit] Could not persist auth session: $error');
    }
  }

  /// Puts the mirrored session back when the hydrated state has none.
  ///
  /// Runs once at startup, before the splash decides where to send the reader.
  /// Two situations reach it: a reinstall on iOS, where the Keychain outlived
  /// the app; and any occasion where the hydrated box was lost or unreadable
  /// while secure storage was not.
  ///
  /// The restored access token may well be expired — that is fine and expected.
  /// The first request 401s, the interceptor refreshes with the restored refresh
  /// token, and the device row it is checked against is keyed by a deviceId that
  /// survives a reinstall too. A refresh token the server no longer recognises
  /// ends in the same sign-in screen the reader would have seen anyway.
  Future<void> restoreAuthSessionIfNeeded() async {
    if (state.accessToken.isNotEmpty) return;

    try {
      final stored = await AppDI.injector.get<ILocalStoreService>().getMap(
            key: LocalStoreKey.authSession,
          );
      if (stored.isEmpty) return;

      final auth = AuthEntity.fromJson(stored);
      if (auth.token.refreshToken.isEmpty || auth.user.id.isEmpty) return;

      AppGlobalValue.accessToken = auth.token.accessToken;
      AppGlobalValue.refreshToken = auth.token.refreshToken;
      setAuth(auth);
      LogDev.info('[UserCubit] Restored session for ${auth.user.id} from secure storage');
    } catch (error) {
      // A blob written by an older shape is not worth crashing the launch over;
      // drop it and let the reader sign in.
      LogDev.warning('[UserCubit] Could not restore auth session: $error');
      await _clearAuthSession();
    }
  }

  Future<void> _clearAuthSession() async {
    try {
      await AppDI.injector.get<ILocalStoreService>().remove(key: LocalStoreKey.authSession);
    } catch (error) {
      LogDev.warning('[UserCubit] Could not clear auth session: $error');
    }
  }

  void setTrackingUser() {
    UserEntity user = state.user;
    if (user.id.isEmpty) return;
    _appTrackingService.setUserId(user.id);
    _appTrackingService.setUserProperties({
      'user_id_property': user.id,
      'user_email_property': user.email,
    });
  }

  Future<void> clearData() async {
    final previousUserId = state.user.id;
    bool isUserPassOnboarding = state.isUserPassOnboarding;
    bool hasCompletedFirstTimeNotificationGate = state.hasCompletedFirstTimeNotificationGate;
    bool hasCompletedCourseEntryNotificationGate = state.hasCompletedCourseEntryNotificationGate;
    List<OnboardingPath> onboardingPathOrder = state.onboardingPathOrder;
    emit(UserState.initial());
    AppDI.injector.get<ProfileCubit>().reset();
    emit(
      state.copyWith(
        isUserPassOnboarding: isUserPassOnboarding,
        hasCompletedFirstTimeNotificationGate: hasCompletedFirstTimeNotificationGate,
        hasCompletedCourseEntryNotificationGate: hasCompletedCourseEntryNotificationGate,
        onboardingPathOrder: onboardingPathOrder,
      ),
    );
    // The mirror goes with the session it mirrors. Leaving it behind would let
    // the next launch restore the very session that was just torn down — a
    // sign-out that undoes itself.
    await _clearAuthSession();
    if (previousUserId.isNotEmpty) {
      await _clearLearningStreakCacheForUser(previousUserId);
    }
    if (AppDI.injector.isRegistered<LearningStreakCubit>()) {
      AppDI.injector.get<LearningStreakCubit>().reset();
    }
    _appTrackingService.setUserId(null);
    _appTrackingService.setUserProperties({});
  }

  void initProfilePage() {}

  void initApp({void Function()? onDone}) async {
    AppGlobalValue.accessToken = state.accessToken;
    AppGlobalValue.refreshToken = state.refreshToken;
    // await Clipboard.setData(ClipboardData(text: AppGlobalValue.accessToken));

    HomeRoute().go(AppConfig.instance.context!);
    onDone?.call();
  }

  Future<void> _clearLearningStreakCacheForUser(String userId) async {
    if (!AppDI.injector.isRegistered<LearningStreakLocalDataSource>()) return;
    await AppDI.injector.get<LearningStreakLocalDataSource>().clearCache(userId: userId);
  }

  Future<void> _markDailyWarmUpOnboardingCompletedDate() async {
    final userId = state.user.id.trim();
    if (userId.isEmpty || !AppDI.injector.isRegistered<DailyWarmUpLocalDataSource>()) return;

    try {
      await AppDI.injector.get<DailyWarmUpLocalDataSource>().markOnboardingCompletedDateIfAbsent(userId, _localDateKey(DateTime.now()));
    } catch (error) {
      LogDev.warning('[UserCubit] daily warm-up onboarding completion mark failed: $error');
    }
  }

  String _localDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
