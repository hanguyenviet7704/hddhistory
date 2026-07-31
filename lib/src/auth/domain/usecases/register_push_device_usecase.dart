part of '../../auth.dart';

class RegisterPushDeviceParams {
  const RegisterPushDeviceParams({
    required this.pushToken,
    required this.pushEnabled,
    required this.platform,
    this.timezone,
    this.language,
  });

  final String pushToken;

  /// The app's OWN notification switch. The server cannot see it, and sending to
  /// a device whose in-app toggle is off would push something the user already
  /// opted out of.
  final bool pushEnabled;

  final String platform;

  /// IANA zone (`Asia/Ho_Chi_Minh`), which is what tells the server when this
  /// user's 08:00 actually is.
  final String? timezone;

  final String? language;

  Map<String, dynamic> toJson() => {
    'pushToken': pushToken,
    'pushEnabled': pushEnabled,
    'platform': platform,
    if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone,
    if (language != null && language!.isNotEmpty) 'language': language,
  };
}

@lazySingleton
class RegisterPushDeviceUsecase implements BaseUseCase<RegisterPushDeviceParams, Unit> {
  final IAuthRepository _authRepository;
  RegisterPushDeviceUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(RegisterPushDeviceParams params) =>
      _authRepository.registerPushDevice(params.toJson());
}
