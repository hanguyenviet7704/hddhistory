part of '../../auth.dart';

abstract interface class IAuthRepository {
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginAnonymous(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginSSOGoogle({String? anonymousUserId});
  TaskEither<AppException, AuthEntity> loginSSOApple({String? anonymousUserId});
  TaskEither<AppException, AuthEntity> register(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> refreshToken(Map<String, dynamic> body);
  TaskEither<AppException, Unit> logout();

  /// Reports this device's push token + locale + IANA zone so the server can
  /// schedule notifications for it. Best-effort by nature: a failure must never
  /// block a login.
  TaskEither<AppException, Unit> registerPushDevice(Map<String, dynamic> body);
  // TaskEither<AppException, BaseResponse<AuthEntity>> forgotPassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> resetPassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> resendOTP(String phone);
  TaskEither<AppException, UserEntity> verifyOTP(Map<String, dynamic> body);
  TaskEither<AppException, Unit> updatePassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> deletePermanentUser(String password);
  TaskEither<AppException, Unit> deleteAccount();
}
