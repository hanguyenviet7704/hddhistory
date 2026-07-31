part of '../../../auth.dart';

@RestApi()
@lazySingleton
abstract class AuthApi {
  @factoryMethod
  factory AuthApi(@Named(DIKey.appDio) Dio dio) = _AuthApi;

  @POST(AppEndpoint.login)
  Future<BaseResponse<AuthModel>> login(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.loginAnonymous)
  Future<BaseResponse<AuthModel>> loginAnonymous(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.loginProvider)
  Future<BaseResponse<AuthModel>> loginProvider(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.register)
  Future<BaseResponse<AuthModel>> register(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.usersRefreshToken)
  Future<BaseResponse<AuthModel>> refreshToken(@Path('id') String userId, @Body() Map<String, dynamic> data);

  @POST(AppEndpoint.logout)
  Future<BaseResponse> logout();

  /// Hands the server this device's FCM token, in-app notification switch, IANA
  /// zone and locale — everything the scheduled notifications need to reach this
  /// user at their own 08:00 / 14:00 / 21:00.
  @POST(AppEndpoint.pushRegistration)
  Future<BaseResponse> registerPushDevice(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.forgotPassword)
  Future<BaseResponse<AuthModel>> forgotPassword(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.resetPassword)
  Future<BaseResponse> resetPassword(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.resendOTP)
  Future<BaseResponse> resendOTP(@Part(name: 'phone') String phone);

  @POST(AppEndpoint.verifyOTP)
  Future<BaseResponse<UserModel>> verifyOTP(@Body() Map<String, dynamic> data);

  @POST(AppEndpoint.updatePassword)
  Future<BaseResponse> updatePassword(@Body() Map<String, dynamic> data);

  @DELETE(AppEndpoint.usersById)
  Future<BaseResponse> deletePermanentUser(@Path('id') String userId);

  @POST(AppEndpoint.deleteAccount)
  Future<BaseResponse> deleteAccount();
}
