part of '../../auth.dart';

@lazySingleton
class UserCubit extends HydratedCubit<UserState> with CubitUseCaseHandlerMixin<UserState> {
  UserCubit(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService) : super(UserState.initial()) {
    // _onAutoSignUpGuest();
  }
  // final RegisterUsecase _registerUsecase;
  final BaseTrackingService _appTrackingService;

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

    emit(state.copyWith(auth: auth));
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
