part of '../../auth.dart';

abstract interface class IAuthRepository {
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginAnonymous(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> loginSSOGoogle();
  TaskEither<AppException, AuthEntity> loginSSOApple();
  TaskEither<AppException, AuthEntity> register(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> logout();
  // TaskEither<AppException, BaseResponse<AuthEntity>> forgotPassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> resetPassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> resendOTP(String phone);
  TaskEither<AppException, BaseResponse<AppUser>> verifyOTP(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> updatePassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> deletePermanentUser(String password);
  TaskEither<AppException, BaseResponse> deleteAccount();
}
