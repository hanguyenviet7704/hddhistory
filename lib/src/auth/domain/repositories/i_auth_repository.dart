part of 'repositories.dart';

abstract interface class IAuthRepository {
  TaskEither<AppException, Auth> login(Map<String, dynamic> body);
  TaskEither<AppException, Auth> loginSSOGoogle();
  TaskEither<AppException, Auth> loginSSOApple();
  TaskEither<AppException, Auth> register(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> logout();
  TaskEither<AppException, BaseResponse<Auth>> forgotPassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> resetPassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> resendOTP(String phone);
  TaskEither<AppException, BaseResponse<AppUser>> verifyOTP(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> updatePassword(Map<String, dynamic> body);
  TaskEither<AppException, BaseResponse> deletePermanentUser(String password);
  TaskEither<AppException, BaseResponse> deleteAccount();
}
