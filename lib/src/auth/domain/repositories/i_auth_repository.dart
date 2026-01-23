part of '../../auth.dart';

abstract interface class IAuthRepository {
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginAnonymous(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginSSOGoogle();
  TaskEither<AppException, AuthEntity> loginSSOApple();
  TaskEither<AppException, AuthEntity> register(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> refreshToken(Map<String, dynamic> body);
  TaskEither<AppException, Unit> logout();
  // TaskEither<AppException, BaseResponse<AuthEntity>> forgotPassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> resetPassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> resendOTP(String phone);
  TaskEither<AppException, UserEntity> verifyOTP(Map<String, dynamic> body);
  TaskEither<AppException, Unit> updatePassword(Map<String, dynamic> body);
  TaskEither<AppException, Unit> deletePermanentUser(String password);
  TaskEither<AppException, Unit> deleteAccount();
}
