part of '../blocs.dart';

@lazySingleton
class UserCubit extends HydratedCubit<UserState> with CubitUseCaseHandlerMixin<UserState> {
  UserCubit(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService, this._getMyProfilesUsecase) : super(UserState.initial()) {
    // _onAutoSignUpGuest();
  }
  // final RegisterUsecase _registerUsecase;
  final GetMyProfilesUsecase _getMyProfilesUsecase;
  final BaseTrackingService _appTrackingService;

  @override
  UserState fromJson(Map<String, dynamic> json) => UserState.fromJson(json);

  @override
  Map<String, dynamic> toJson(UserState state) => state.toJson();

  bool fakeUserFullRoadmap() => kDebugMode && state.user.email == "truongdev109@gmail.com";

  void setIsFirstTime(bool isFirstTime) => emit(state.copyWith(isFirstTimeUserAccessApp: isFirstTime));
  void setIsFirstTimeUserAccessPictureStudy(bool isFirstTimeUserAccessPictureStudy) => emit(state.copyWith(isFirstTimeUserAccessPictureStudy: isFirstTimeUserAccessPictureStudy));
  void setIsFirstTimeUserRunApp(bool isFirstTimeUserRunApp) => emit(state.copyWith(isFirstTimeUserRunApp: isFirstTimeUserRunApp));
  void setIsAppShowRegisterRecommend(bool isAppShowRegisterRecommend) => emit(state.copyWith(isAppShowRegisterRecommend: isAppShowRegisterRecommend));

  void setAuth(Auth auth) {
    emit(state.copyWith(auth: auth));
    setTrackingUser();

    if (auth.user.id.isEmpty) return;
    // getMyProfiles();
    // AppConfig.instance.context!.read<PaywallCubit>()
    //   ..reactiveFakePremium(auth.user.id)
    //   ..addUserPremiumId(auth.user.id);
  }

  void setTrackingUser() {
    AppUser user = state.user;
    if (user.id.isEmpty) return;
    _appTrackingService.setUserId(user.id);
    _appTrackingService.setUserProperties({
      'user_id_property': user.id,
      'user_email_property': user.email,
      'user_phone_property': user.phone,
    });
  }

  Future<void> clearData() async {
    bool isFirstTime = state.isFirstTimeUserAccessApp;
    bool isGuest = state.isGuest;
    emit(UserState.initial());
    emit(state.copyWith(isFirstTimeUserAccessApp: isFirstTime, isGuest: isGuest));
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

  // ignore: unused_element
  Future<void> _onAutoSignUpGuest() async {
    if (!state.isGuest || state.accessToken.isNotEmpty) return;
    final uuid = Uuid().v4();
    // await executeCustomUseCase(
    //   usecase: () => _registerUsecase({
    //     'email': 'guest_$uuid@meup.com',
    //     'password': '123456',
    //     'password_confirmation': '123456',
    //     'data': {},
    //     'gotrue_meta_security': {},
    //     'code_challenge': null,
    //     'code_challenge_method': null,
    //   }),
    //   onSuccess: (response) async {
    //     // AppGlobalValue.accessToken = response.accessToken;
    //     // AppGlobalValue.refreshToken = response.refreshToken;
    //     // setAuth(response);
    //     _onGetMyProfiles();
    //   },
    //   onFailure: (failure) {
    //     DMessage.showMessage(message: AppConfig.instance.context!.text.authRegistrationFailedPleaseTryAgain, type: MessageType.error);
    //   },
    // );
  }

  Future<void> _onGetMyProfiles() async {
    await executeCustomUseCase(
      usecase: () => _getMyProfilesUsecase(),
      onSuccess: (response) {
        if (response.data.isEmpty) return;
        emit(state.copyWith(guestProfileId: response.data.first.id));
      },
      onFailure: (p0) {
        debugPrint('onGetMyProfiles error: $p0');
      },
    );
  }

  void getMyProfiles() async {
    await executeListUseCase(
      usecase: _getMyProfilesUsecase.call,
      onSuccess: (response) {
        if (response.data.isEmpty) return;
        LogDev.info('getMyProfiles: ${response.data.first}');
        _appTrackingService.setUserId(response.data.first.userId);
        emit(state.copyWith(profile: response.data.first));
      },
    );
  }

  void setIsGuest(bool isGuest) {
    AppGlobalValue.isGuest = isGuest;
    emit(state.copyWith(isGuest: isGuest));
  }
}
