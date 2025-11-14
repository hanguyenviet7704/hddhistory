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

  bool fakeUserFullRoadmap() => kDebugMode && state.user.email == "truongdev109@gmail.com";

  void setIsFirstTime(bool isFirstTime) => emit(state.copyWith(isFirstTimeUserAccessApp: isFirstTime));
  void setIsFirstTimeUserRunApp(bool isFirstTimeUserRunApp) => emit(state.copyWith(isFirstTimeUserRunApp: isFirstTimeUserRunApp));

  void setAccessToken(String accessToken) {
    AppGlobalValue.accessToken = accessToken;
    TokenEntity token = TokenEntity(accessToken: accessToken, refreshToken: state.refreshToken, expiresAt: DateTime.now().add(Duration(seconds: 30)));
    AuthEntity auth = state.auth.copyWith(token: token);
    emit(state.copyWith(auth: auth));
  }

  void setAuth(AuthEntity auth) {
    emit(state.copyWith(auth: auth));
    setTrackingUser();

    if (auth.user.id.isEmpty) return;
    // getMyProfiles();
    // AppConfig.instance.context!.read<PaywallCubit>()
    //   ..reactiveFakePremium(auth.user.id)
    //   ..addUserPremiumId(auth.user.id);
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
    bool isFirstTime = state.isFirstTimeUserAccessApp;
    emit(UserState.initial());
    emit(state.copyWith(isFirstTimeUserAccessApp: isFirstTime));
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


  void getMyProfiles() async {
    // await executeListUseCase(
    //   usecase: _getMyProfilesUsecase.call,
    //   onSuccess: (response) {
    //     if (response.data.isEmpty) return;
    //     LogDev.info('getMyProfiles: ${response.data.first}');
    //     _appTrackingService.setUserId(response.data.first.userId);
    //     emit(state.copyWith(profile: response.data.first));
    //   },
    // );
  }
}

