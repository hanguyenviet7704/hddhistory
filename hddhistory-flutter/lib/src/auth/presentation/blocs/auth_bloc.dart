// ignore_for_file: unused_field

part of '../../auth.dart';

enum AuthSuccessRouteDestination { course, home }

enum RegisterGuestContinueAction { continueCurrentSession, loginAnonymousAndNavigate }

enum CourseEntryBootstrapResult { success, retryableFailure, unrecoverableFailure }

Map<String, dynamic> buildAnonymousDeviceAuthPayload({
  required String deviceId,
  required String deviceName,
  required String languageCode,
}) {
  return {
    "device": {
      "deviceId": deviceId,
      "deviceName": deviceName,
    },
    "language": languageCode,
  };
}

@visibleForTesting
AuthSuccessRouteDestination resolveAuthSuccessRouteDestination({
  required bool forceChooseCourseAfterLogin,
  required bool hasCourseData,
}) {
  if (forceChooseCourseAfterLogin || !hasCourseData) {
    return AuthSuccessRouteDestination.course;
  }

  return AuthSuccessRouteDestination.home;
}

@visibleForTesting
bool shouldConsumeFirstTimePaywallIntentAfterAuth({
  required bool showPaywallAfterAuth,
  bool hasPendingFirstTimePaywallAfterAuth = false,
}) {
  return showPaywallAfterAuth || hasPendingFirstTimePaywallAfterAuth;
}

@visibleForTesting
RegisterGuestContinueAction resolveRegisterGuestContinueAction({
  required bool hasBootstrappedGuestSession,
}) {
  if (hasBootstrappedGuestSession) {
    return RegisterGuestContinueAction.continueCurrentSession;
  }

  return RegisterGuestContinueAction.loginAnonymousAndNavigate;
}

@visibleForTesting
CourseEntryBootstrapResult resolveCourseEntryBootstrapResult(AppException? failure) {
  return switch (failure) {
    UnauthorizedException() || ForbiddenException() || InvalidInputException() => CourseEntryBootstrapResult.unrecoverableFailure,
    _ => CourseEntryBootstrapResult.retryableFailure,
  };
}

@visibleForTesting
bool isCourseEntryDataReady({
  required HomeState homeState,
  required ProgressState progressState,
  required ProfileState profileState,
}) {
  final hasCourseCatalog = homeState.status == HomeStatus.success && homeState.categories.any((category) => category.courses.isNotEmpty);
  final hasBlockingFailure = progressState.status == ProgressStatus.failure || profileState.status == ProfileStatus.failure;
  return hasCourseCatalog && !hasBlockingFailure;
}

@visibleForTesting
int? resolveAuthSuccessSelectedCourseTabIndex({
  required AuthSuccessRouteDestination destination,
  required bool resetToFirstCourseCategory,
}) {
  if (destination != AuthSuccessRouteDestination.course || !resetToFirstCourseCategory) {
    return null;
  }

  return 0;
}

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocUseCaseHandlerMixin<AuthEvent, AuthState> {
  final LoginUsecase _loginUsecase;
  final LoginAnonymousUsecase _loginAnonymousUsecase;
  final LogoutUsecase _logoutUsecase;
  final LoginSSOGoogleUsecase _loginSSOGoogleUsecase;
  final LoginSSOAppleUsecase _loginSSOAppleUsecase;
  final RegisterUsecase _registerUsecase;
  final ForgotPasswordUsecase _forgotPasswordUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;
  final ResendOtpUsecase _resendOtpUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final DeletePermanentUserUsecase _deletePermanentUserUsecase;
  final RefreshTokenUsecase _refreshTokenUsecase;
  final RegisterPushDeviceUsecase _registerPushDeviceUsecase;
  final SyncHomeWidgetsUseCase _syncHomeWidgetsUseCase;
  final ClearHomeWidgetsUseCase _clearHomeWidgetsUseCase;

  final IDeviceInfoService _deviceInfoService;
  final UserCubit _userCubit;
  final ProfileCubit _profileCubit;
  final HomeCubit _homeCubit;
  final ProgressCubit _progressCubit;
  final PageCubit _pageCubit;
  final CourseRoadmapCubit _courseRoadmapCubit;

  /// In-flight (or completed) home-dataset prewarm for the guest course-entry
  /// flow. Started at splash warm-up so the list-course/progress/user calls
  /// overlap with the DataCollect animations + the notification gate, instead
  /// of blocking navigation at the end. Reset when a load comes back not-ready
  /// so a later bootstrap can retry.
  Future<void>? _courseEntryHomeInitFuture;
  final LocaleCubit _localeCubit;
  final IapCubit _iapCubit;

  static Completer<bool>? _refreshCompleter;
  Completer<bool>? _anonymousAuthCompleter;
  AppException? _lastAnonymousAuthFailure;
  // Re-entrancy guard for the awaitable deleteAccountPermanently() (this Bloc
  // can't emit a loading state outside an event handler).
  bool _isDeletingAccount = false;

  AuthBloc(
    this._loginUsecase,
    this._loginAnonymousUsecase,
    this._logoutUsecase,
    this._loginSSOGoogleUsecase,
    this._loginSSOAppleUsecase,
    this._registerUsecase,
    this._forgotPasswordUsecase,
    this._resetPasswordUsecase,
    this._resendOtpUsecase,
    this._deleteAccountUsecase,
    this._deletePermanentUserUsecase,
    this._refreshTokenUsecase,
    this._registerPushDeviceUsecase,
    this._syncHomeWidgetsUseCase,
    this._clearHomeWidgetsUseCase,
    this._deviceInfoService,
    this._userCubit,
    this._profileCubit,
    this._homeCubit,
    this._progressCubit,
    this._pageCubit,
    this._courseRoadmapCubit,
    this._localeCubit,
    this._iapCubit,
  ) : super(AuthState.initial()) {
    on<_LoginAnonymous>(_onLoginAnonymous);
    on<_LoginAnonymousGuest>(_onLoginAnonymousGuest);
    on<_LoginSSOGoogle>(_onLoginSSOGoogle);
    on<_LoginSSOApple>(_onLoginSSOApple);
    on<_Register>(_onRegister);
    on<_Logout>(_onLogout);
    on<_DeleteAccountPermanently>(_onDeletePermanentUser);
    on<_ClearSession>(_onClearSession);

    // FCM issues the FIRST token only once notification permission is granted —
    // which on iOS is usually AFTER login, since the token needs an APNs
    // registration that a denied prompt never produces. Registering only in
    // [_onAuthSuccess] therefore missed exactly the people who said yes on the
    // second ask: `getToken()` was null at login, the sync returned early, and
    // nothing sent the token that arrived a moment later. The server kept
    // reporting "user has no push token" until they signed out and back in.
    //
    // The stream carries genuine refreshes only — `syncInitialToken` publishes
    // with `emitToStream: false` — and never an empty token, so every event
    // here is worth acting on.
    _pushTokenRefreshSubscription = NotificationService.tokenRefreshStream.listen((tokenState) {
      if (!tokenState.hasToken) return;
      // No session yet: `push-registration` writes onto the device row that
      // login creates, so there is nothing to attach to and the call would
      // 404. [_onAuthSuccess] picks the token up when login lands.
      if (AppGlobalValue.accessToken.isEmpty) return;
      unawaited(syncPushRegistration());
    });
  }

  /// Keeps the server's copy of this device's FCM token current — see the
  /// listener in the constructor for why login alone is not enough.
  StreamSubscription<NotificationTokenState>? _pushTokenRefreshSubscription;

  @override
  Future<void> close() async {
    await _pushTokenRefreshSubscription?.cancel();
    return super.close();
  }

  void _onAuthSuccess(AuthEntity auth) {
    _userCubit.setAuth(auth);
    AppGlobalValue.accessToken = auth.token.accessToken;
    AppGlobalValue.refreshToken = auth.token.refreshToken;
    _profileCubit.loadUser();
    unawaited(_syncHomeWidgetsUseCase(HomeWidgetSyncParams(localeCode: _localeCubit.state.languageCode)).run());
    unawaited(syncPushRegistration());
  }

  /// Tells the server which device this session is on, so the scheduled
  /// notifications (08:00 / 14:00 / 21:00 local) can reach it.
  ///
  /// Called after every login path — the device row the token is written onto is
  /// created by that login — and again on an FCM token refresh (see the
  /// `tokenRefreshStream` listener in the constructor). Entirely best-effort: a
  /// failure here must never surface to someone who just signed in, so it only
  /// logs.
  Future<void> syncPushRegistration() async {
    try {
      final pushToken = await NotificationService.getToken();
      if (pushToken == null || pushToken.isEmpty) return;

      await _registerPushDeviceUsecase(
        RegisterPushDeviceParams(
          pushToken: pushToken,
          pushEnabled: await isAppNotificationPreferenceEnabled(),
          platform: Platform.isIOS ? 'ios' : 'android',
          timezone: await _resolveTimezone(),
          language: _localeCubit.state.languageCode,
        ),
      ).run();
    } catch (error) {
      LogDev.warning('[AuthBloc] push registration failed: $error');
    }
  }

  /// IANA zone of the device. Sent as null when the platform channel fails
  /// rather than guessing: the server treats a missing zone as "not schedulable"
  /// instead of nudging someone at 08:00 UTC.
  Future<String?> _resolveTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (error) {
      LogDev.warning('[AuthBloc] could not resolve timezone: $error');
      return null;
    }
  }

  Future<bool> _userHaveCourseData() async {
    // Roadmap and my-courses loads are independent — run them together instead
    // of firing roadmap then serially awaiting my-courses.
    await Future.wait<void>([
      _courseRoadmapCubit.loadRoadmap(),
      _progressCubit.loadUserProgressMyCourses(isInit: true, recent: true),
    ]);
    final List<CourseEntity> myCourses = _progressCubit.state.myCourses;
    return myCourses.isNotEmpty;
  }

  Future<void> _navigateAfterAuth({
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
    bool resetToFirstCourseCategory = false,
    bool isSameSessionContinue = false,
  }) async {
    // Clear the previous account's roadmap/progress before loading the new
    // one. CourseRoadmapCubit is a HydratedCubit, so without this an account
    // switch (e.g. guest → login) would keep stale roadmap/lesson progress
    // (wrong "x/y lessons" and completion %). Skipped when continuing the
    // SAME anonymous session that was just bootstrapped moments ago (e.g.
    // register_page's mount-time bootstrap): no account switch happened, so
    // there's nothing stale to clear and the in-memory roadmap/myCourses data
    // from that bootstrap is still valid — resetting + re-fetching here would
    // just be thrown-away network work.
    if (!isSameSessionContinue) {
      _resetAppCubits();
    }

    final hasPendingFirstTimePaywallAfterAuth = _userCubit.state.hasPendingFirstTimePaywallAfterAuth;
    if (shouldConsumeFirstTimePaywallIntentAfterAuth(
      showPaywallAfterAuth: showPaywallAfterAuth,
      hasPendingFirstTimePaywallAfterAuth: hasPendingFirstTimePaywallAfterAuth,
    )) {
      _userCubit.consumeFirstTimePaywallAfterAuthIntent();
    }

    final bool hasCourseData;
    if (forceChooseCourseAfterLogin) {
      hasCourseData = false;
    } else if (isSameSessionContinue) {
      // Data already in memory from the bootstrap that just ran seconds ago —
      // read it directly instead of re-awaiting the roadmap/myCourses fetch.
      hasCourseData = _progressCubit.state.myCourses.isNotEmpty;
    } else {
      hasCourseData = await _userHaveCourseData();
    }

    final destination = resolveAuthSuccessRouteDestination(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      hasCourseData: hasCourseData,
    );
    final selectedTabIndex = resolveAuthSuccessSelectedCourseTabIndex(
      destination: destination,
      resetToFirstCourseCategory: resetToFirstCourseCategory,
    );

    switch (destination) {
      case AuthSuccessRouteDestination.course:
        await _homeCubit.initializeData(isInit: true);
        if (selectedTabIndex != null) {
          _homeCubit.resetSelection(categoryIndex: selectedTabIndex);
        }
        CourseRoute(selectedTabIndex: selectedTabIndex).go(AppConfig.instance.context!);
        return;
      case AuthSuccessRouteDestination.home:
        HomeRoute().go(AppConfig.instance.context!);
        _pageCubit.setCurrentIndex(0);
    }
  }

  void _onResetAuth() {
    unawaited(_clearHomeWidgetsUseCase(unit).run());
    _userCubit.clearData();
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';
    _resetAppCubits();
    // Only leave the current screen when the session died on an AUTHENTICATED
    // one. Re-going to RegisterRoute from a pre-auth screen replaces it with a
    // fresh instance (restarting the register screen's mount-time bootstrap),
    // and a 401 burst re-fires this reset every ~2s — that remount loop is what
    // made the welcome screen permanently untappable after a reinstall.
    final context = AppConfig.instance.context;
    if (context == null) return;
    if (shouldForceRegisterNavigationAfterReset(_pageCubit.state.currentRouteName)) {
      RegisterRoute().go(context);
    }
  }

  void _resetAppCubits() {
    _courseRoadmapCubit.reset();
    _progressCubit.reset();
    // IapCubit cố ý KHÔNG reset ở đây: state của nó chỉ là cấu hình sản phẩm /
    // paywall ở mức ứng dụng — quyền premium nằm trên người dùng qua
    // ProfileCubit, thứ đã được reset ở cùng những lần chuyển này.
    // Community is the same shape of problem: a lazySingleton holding the
    // previous session's feed, the reader's posting rights and the unread
    // badge. It bites hardest on guest → login, because that is the transition
    // the forum's own sign-in notice starts: without this the reader signs in,
    // comes back to the tab, and is still invited to sign in — `ensureLoaded`
    // trusts the loaded copy for two minutes and does nothing.
    if (AppDI.injector.isRegistered<CommunityFeedCubit>()) {
      AppDI.injector.get<CommunityFeedCubit>().reset();
    }
  }

  bool get hasActiveAnonymousSession => _userCubit.state.user.anonymous && AppGlobalValue.accessToken.isNotEmpty;

  /// The current guest's userId to hand to a provider (Google/Apple) login so
  /// the backend upgrades THAT guest in place (preserving its progress).
  /// Null when the current user isn't an anonymous guest.
  String? get _anonymousUserIdForUpgrade {
    final user = _userCubit.state.user;
    return (user.anonymous && user.id.isNotEmpty) ? user.id : null;
  }

  Future<bool> bootstrapGuestSessionForRegister() async {
    try {
      if (hasActiveAnonymousSession) {
        await _homeCubit.initializeData(isInit: true);
        return true;
      }

      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (success) {
        await _homeCubit.initializeData(isInit: true);
      }
      return success;
    } catch (error) {
      LogDev.warning('[AuthBloc] bootstrapGuestSessionForRegister failed: $error');
      return false;
    }
  }

  Future<void> warmUpCourseEntrySession() async {
    try {
      if (!hasActiveAnonymousSession) {
        final payload = await _buildAnonymousDeviceLoginPayload();
        final success = await _authenticateAnonymousSession(payload);
        if (!success) return;
      }
      // Session ready → prewarm the home dataset so it's loaded by the time the
      // user finishes the DataCollect / notification gate and bootstrap runs.
      unawaited(_prewarmCourseEntryHomeData());
    } catch (error) {
      LogDev.warning('[AuthBloc] warmUpCourseEntrySession failed: $error');
    }
  }

  /// Loads the home dataset at most once per warm-up, reusing the in-flight
  /// future so bootstrap awaits the SAME fetch instead of a fresh one.
  Future<void> _prewarmCourseEntryHomeData() {
    return _courseEntryHomeInitFuture ??= _runCourseEntryHomePrewarm();
  }

  Future<void> _runCourseEntryHomePrewarm() async {
    await _homeCubit.initializeData(isInit: true);
    // Don't cache an empty/failed prewarm: if categories didn't load, drop the
    // cache so bootstrap's retry re-fetches instead of reusing a blank result.
    if (_homeCubit.state.categories.isEmpty) {
      _courseEntryHomeInitFuture = null;
    }
  }

  Future<CourseEntryBootstrapResult> bootstrapCourseEntrySession() async {
    try {
      if (hasActiveAnonymousSession) {
        return await _initializeCourseEntryData() ? CourseEntryBootstrapResult.success : CourseEntryBootstrapResult.retryableFailure;
      }

      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (!success) {
        return resolveCourseEntryBootstrapResult(_lastAnonymousAuthFailure);
      }

      return await _initializeCourseEntryData() ? CourseEntryBootstrapResult.success : CourseEntryBootstrapResult.retryableFailure;
    } catch (error) {
      LogDev.warning('[AuthBloc] bootstrapCourseEntrySession failed: $error');
      return CourseEntryBootstrapResult.retryableFailure;
    }
  }

  Future<bool> _initializeCourseEntryData() async {
    // Await the prewarmed load (started at splash warm-up) — near-zero when it
    // already finished, instead of a cold fetch on the critical path.
    await _prewarmCourseEntryHomeData();
    final isReady = isCourseEntryDataReady(
      homeState: _homeCubit.state,
      progressState: _progressCubit.state,
      profileState: _profileCubit.state,
    );
    if (!isReady) {
      // Drop the cached (incomplete) load so the next bootstrap re-fetches.
      _courseEntryHomeInitFuture = null;
      LogDev.warning('[AuthBloc] Course entry data bootstrap incomplete');
      return false;
    }

    _homeCubit.resetSelection(categoryIndex: 0);
    return true;
  }

  // Not itself a registered event handler (no local `Emitter` param), so it
  // can't call `emit` directly here (see `_onLogout`/SSO handlers for that
  // pattern) — callers track their own busy state instead: RegisterPage
  // awaits this method directly and tracks the span in a local
  // try/finally, since (unlike dispatching a bloc event) this is a plain
  // awaitable method.
  Future<void> continueWithCurrentGuestSession({
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) async {
    // Captured before any fresh login below: true here means no login POST
    // is about to happen in this call — an earlier bootstrap (e.g.
    // register_page's mount-time bootstrap) already authenticated this
    // anonymous session, so this is a same-session continue, not an account
    // switch.
    final isSameSessionContinue = hasActiveAnonymousSession;
    final action = resolveRegisterGuestContinueAction(
      hasBootstrappedGuestSession: isSameSessionContinue,
    );

    if (action == RegisterGuestContinueAction.loginAnonymousAndNavigate) {
      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (!success) {
        return;
      }
    }

    await _navigateAfterAuth(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      showPaywallAfterAuth: showPaywallAfterAuth,
      resetToFirstCourseCategory: true,
      isSameSessionContinue: isSameSessionContinue,
    );
  }

  void _loginAnonymous(
    Map<String, dynamic> data, {
    bool navigateAfterSuccess = false,
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) {
    unawaited(
      _authenticateAnonymousSession(
        data,
        navigateAfterSuccess: navigateAfterSuccess,
        forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
        showPaywallAfterAuth: showPaywallAfterAuth,
      ),
    );
  }

  Future<bool> _authenticateAnonymousSession(
    Map<String, dynamic> data, {
    bool navigateAfterSuccess = false,
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) async {
    final inFlight = _anonymousAuthCompleter;
    if (inFlight != null) {
      final success = await inFlight.future;
      if (success && navigateAfterSuccess) {
        await _navigateAfterAuth(
          forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
          showPaywallAfterAuth: showPaywallAfterAuth,
        );
      }
      return success;
    }

    final completer = Completer<bool>();
    _anonymousAuthCompleter = completer;

    void complete(bool success) {
      if (!completer.isCompleted) {
        completer.complete(success);
      }
      if (identical(_anonymousAuthCompleter, completer)) {
        _anonymousAuthCompleter = null;
      }
    }

    unawaited(
      _loginAnonymousUsecase(data)
          .run()
          .then((result) {
            result.match(
              (failure) {
                _lastAnonymousAuthFailure = failure;
                complete(false);
              },
              (auth) {
                _lastAnonymousAuthFailure = null;
                _onAuthSuccess(auth);
                complete(true);
                if (navigateAfterSuccess) {
                  unawaited(
                    _navigateAfterAuth(
                      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
                      showPaywallAfterAuth: showPaywallAfterAuth,
                    ),
                  );
                }
              },
            );
          })
          .catchError((Object error) {
            LogDev.warning('[AuthBloc] Anonymous auth failed unexpectedly: $error');
            _lastAnonymousAuthFailure = const AppException.unexpected();
            complete(false);
          }),
    );

    return completer.future;
  }

  Future<Map<String, dynamic>> _buildAnonymousDeviceLoginPayload() async {
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = _localeCubit.state.languageCode;

    return buildAnonymousDeviceAuthPayload(
      deviceId: deviceId,
      deviceName: deviceName,
      languageCode: languageCode,
    );
  }

  Future<bool> loginAnonymousSilently(Map<String, dynamic> data) async {
    try {
      return await _authenticateAnonymousSession(data);
    } catch (error) {
      LogDev.warning('[AuthBloc] loginAnonymousSilently failed: $error');
      return false;
    }
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    _loginAnonymous(event.data);
  }

  Future<void> _onLoginAnonymousGuest(_LoginAnonymousGuest event, Emitter<AuthState> emit) async {
    await continueWithCurrentGuestSession(
      forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
      showPaywallAfterAuth: event.showPaywallAfterAuth,
    );
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    // Guards a fast double-tap on the Google button from dispatching two
    // concurrent sign-in attempts (default EventTransformer runs events
    // concurrently, not sequentially). Also lets RegisterPage read
    // `state.status == AuthStatus.loading` to drive the button's spinner,
    // since `add()` itself can't be awaited by the caller.
    if (state.status == AuthStatus.loading) return null;

    return runUseCase(
      usecase: () => _loginSSOGoogleUsecase(_anonymousUserIdForUpgrade),
      buildLoadingState: () => state.copyWith(status: AuthStatus.loading),
      onSuccess: (data) {
        emit(state.copyWith(status: AuthStatus.success));
        _onAuthSuccess(data);
        _navigateAfterAuth(
          forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: event.showPaywallAfterAuth,
        );
      },
      onFailure: (error) {
        emit(state.copyWith(status: AuthStatus.failure, errorMessage: error));
        DMessage.showMessage(message: error, type: MessageType.error);
      },
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    if (state.status == AuthStatus.loading) return null;

    return runUseCase(
      usecase: () => _loginSSOAppleUsecase(_anonymousUserIdForUpgrade),
      buildLoadingState: () => state.copyWith(status: AuthStatus.loading),
      onSuccess: (data) {
        emit(state.copyWith(status: AuthStatus.success));
        _onAuthSuccess(data);
        _navigateAfterAuth(
          forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: event.showPaywallAfterAuth,
        );
      },
      onFailure: (error) {
        emit(state.copyWith(status: AuthStatus.failure, errorMessage: error));
        DMessage.showMessage(message: error, type: MessageType.error);
      },
    );
  }

  FutureOr<void> _onRegister(_Register event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _registerUsecase({
        "email": event.email,
        "password": event.password,
        "passwordConfirm": event.passwordConfirm,
      }),
      onSuccess: (data) {
        _onAuthSuccess(data);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLogout(_Logout event, Emitter<AuthState> emit) async {
    // Guards against a fast double-tap on "Log Out" dispatching two logout
    // events that would run concurrently (the default EventTransformer
    // processes events concurrently, not sequentially).
    if (state.status == AuthStatus.loading) return;

    await runUseCase(
      usecase: () => _logoutUsecase(unit),
      buildLoadingState: () => state.copyWith(status: AuthStatus.loading),
      onSuccess: (data) {
        emit(state.copyWith(status: AuthStatus.success));
        _onResetAuth();
        unawaited(bootstrapGuestSessionForRegister());
      },
      onFailure: (error) {
        emit(state.copyWith(status: AuthStatus.failure, errorMessage: error));
        DMessage.showMessage(message: error, type: MessageType.error);
      },
    );
  }

  Future<void> _onDeletePermanentUser(_DeleteAccountPermanently event, Emitter<AuthState> emit) async {
    // Same concurrency guard as _onLogout — prevents a double-tap/duplicate
    // dispatch from firing the delete-account use case twice in parallel.
    if (state.status == AuthStatus.loading) return;
    await deleteAccountPermanently(event.userId);
  }

  /// Awaitable account deletion for callers that need the real outcome (e.g.
  /// the profile page's confirm dialog). The old flow dispatched the event
  /// then awaited `authBloc.stream.firstWhere(success|failure)`, which HANGS
  /// forever if the `AuthStatus.loading` guard above early-returns (no state
  /// is emitted), and could also match an unrelated concurrent auth op's
  /// state. This returns the outcome directly instead. On success it resets
  /// the session and re-bootstraps a guest (same as logout); navigation is
  /// handled by `_onResetAuth`, so callers must NOT also pop/navigate.
  Future<bool> deleteAccountPermanently(String userId) async {
    // AuthBloc extends Bloc (not Cubit), so this non-handler method can't emit
    // AuthState — it guards re-entrancy with a plain flag instead of
    // `status == loading`, and returns the outcome directly.
    if (_isDeletingAccount) return false;
    _isDeletingAccount = true;
    try {
      final result = await _deletePermanentUserUsecase(userId).run();
      return result.match(
        (failure) {
          DMessage.showMessage(message: failure.displayMessage, type: MessageType.error);
          return false;
        },
        (_) {
          _onResetAuth();
          unawaited(bootstrapGuestSessionForRegister());
          return true;
        },
      );
    } finally {
      _isDeletingAccount = false;
    }
  }

  Future<bool> refreshAccessToken() async {
    final existingCompleter = _refreshCompleter;
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    try {
      final refreshToken = AppGlobalValue.refreshToken;
      final userId = _userCubit.state.user.id;
      String deviceId = await _deviceInfoService.deviceToken;
      String deviceName = await _deviceInfoService.deviceName;

      if (refreshToken.isEmpty || userId.isEmpty) {
        LogDev.warning('[AuthBloc] Token refresh skipped: Missing refresh token or user id');
        complete(false);
        return completer.future;
      }

      LogDev.info('[AuthBloc] Access token expired, attempting to refresh...');

      final result = await _refreshTokenUsecase({
        "userId": userId,
        "refreshToken": refreshToken,
        "device": {
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
      }).run();

      final refreshed = result.match(
        (failure) {
          LogDev.error('[AuthBloc] Token refresh failed: ${failure.displayMessage}');
          return false;
        },
        (auth) {
          if (auth.token.accessToken.isEmpty) {
            LogDev.error('[AuthBloc] Token refresh failed: Empty access token returned');
            return false;
          }

          AppGlobalValue.accessToken = auth.token.accessToken;
          _userCubit.setAccessToken(auth.token.accessToken);

          LogDev.info('[AuthBloc] Token refreshed successfully, retrying original request...');
          return true;
        },
      );

      complete(refreshed);
    } catch (error, stackTrace) {
      LogDev.error('[AuthBloc] Failed to refresh token: $error\n$stackTrace');
      complete(false);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  Future<void> _onClearSession(_ClearSession event, Emitter<AuthState> emit) async {
    _onResetAuth();
    unawaited(bootstrapGuestSessionForRegister());
  }
}
