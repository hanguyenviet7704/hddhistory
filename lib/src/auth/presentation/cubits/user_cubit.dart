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

  void setIsUserPassOnboarding(bool isUserPassOnboarding) => emit(state.copyWith(isUserPassOnboarding: isUserPassOnboarding));
  void setIsAppEventConfigured(bool isAppEventConfigured) => emit(state.copyWith(isAppEventConfigured: isAppEventConfigured));
  void setIsFirstTimeUserAccessLessonList(bool isFirstTimeUserAccessLessonList) => emit(state.copyWith(isFirstTimeUserAccessLessonList: isFirstTimeUserAccessLessonList));
  void setIsFirstTimeUserChooseCourse(bool isFirstTimeUserChooseCourse) => emit(state.copyWith(isFirstTimeUserChooseCourse: isFirstTimeUserChooseCourse));

  void setAccessToken(String accessToken) {
    AppGlobalValue.accessToken = accessToken;
    TokenEntity token = TokenEntity(accessToken: accessToken, refreshToken: state.refreshToken, expiresAt: DateTime.now().add(Duration(seconds: 30)));
    AuthEntity auth = state.auth.copyWith(token: token);
    emit(state.copyWith(auth: auth));
  }

  void setAuth(AuthEntity auth) {
    emit(state.copyWith(auth: auth));
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
    bool isUserPassOnboarding = state.isUserPassOnboarding;
    emit(UserState.initial());
    AppDI.injector.get<ProfileCubit>().reset();
    emit(state.copyWith(isUserPassOnboarding: isUserPassOnboarding));
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
}
