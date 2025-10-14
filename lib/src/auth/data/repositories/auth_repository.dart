part of 'repositories.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin implements IAuthRepository {
  final AuthApi _authApi;
  AuthRepository(this._authApi);

  @override
  TaskEither<AppException, Auth> login(Map<String, dynamic> body) {
    return TaskEither.tryCatch(
      () async {
        AuthResponse response = await AppDI.injector.get<SupabaseService>().signInWithPassword(
          email: body['email'] as String,
          password: body['password'] as String,
        );
        return Auth(
          accessToken: response.session?.accessToken ?? '',
          tokenType: response.session?.tokenType ?? '',
          expiresIn: response.session?.expiresIn ?? 0,
          expiresAt: response.session?.expiresIn ?? 0,
          refreshToken: response.session?.refreshToken ?? '',
          user: AppUser.fromJson(response.user?.toJson() ?? {}),
        );
      },
      (error, stackTrace) {
        if (error is AuthException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, Auth> loginSSOGoogle() {
    return TaskEither.tryCatch(
      () async {
        AuthResponse response = await AppDI.injector.get<SupabaseService>().signInWithGoogle();
        return Auth(
          accessToken: response.session?.accessToken ?? '',
          tokenType: response.session?.tokenType ?? '',
          expiresIn: response.session?.expiresIn ?? 0,
          expiresAt: response.session?.expiresIn ?? 0,
          refreshToken: response.session?.refreshToken ?? '',
          user: AppUser.fromJson(response.user?.toJson() ?? {}),
        );
      },
      (error, stackTrace) {
        if (error is AuthException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, Auth> loginSSOApple() {
    return TaskEither.tryCatch(
      () async {
        AuthResponse response = await AppDI.injector.get<SupabaseService>().signInWithApple();
        return Auth(
          accessToken: response.session?.accessToken ?? '',
          tokenType: response.session?.tokenType ?? '',
          expiresIn: response.session?.expiresIn ?? 0,
          expiresAt: response.session?.expiresIn ?? 0,
          refreshToken: response.session?.refreshToken ?? '',
          user: AppUser.fromJson(response.user?.toJson() ?? {}),
        );
      },
      (error, stackTrace) {
        if (error is AuthException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, Auth> register(Map<String, dynamic> body) {
    return TaskEither.tryCatch(
      () async {
        AuthResponse response = await AppDI.injector.get<SupabaseService>().signUp(
          email: body['email'] as String,
          password: body['password'] as String,
          data: {
            'email': body['email'] as String,
            'username': 'user_${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        LogDev.info('register response: ${response.user?.toJson().toString()}');
        return Auth(
          accessToken: response.session?.accessToken ?? '',
          tokenType: response.session?.tokenType ?? '',
          expiresIn: response.session?.expiresIn ?? 0,
          expiresAt: response.session?.expiresIn ?? 0,
          refreshToken: response.session?.refreshToken ?? '',
          user: AppUser.fromJson(response.user?.toJson() ?? {}),
        );
      },
      (error, stackTrace) {
        if (error is AuthException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, BaseResponse<Auth>> forgotPassword(Map<String, dynamic> body) {
    return callApi(apiCall: () => _authApi.forgotPassword(body));
  }

  @override
  TaskEither<AppException, BaseResponse> logout() {
    // return callApi(apiCall: () => _authApi.logout());
    return TaskEither.tryCatch(
      () async {
        await AppDI.injector.get<SupabaseService>().signOutAndClearData();
        return BaseResponse(data: unit);
      },
      (error, stackTrace) {
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, BaseResponse> resendOTP(String phone) {
    return callApi(apiCall: () => _authApi.resendOTP(phone));
  }

  @override
  TaskEither<AppException, BaseResponse> resetPassword(Map<String, dynamic> body) {
    return callApi(apiCall: () => _authApi.resetPassword(body));
  }

  @override
  TaskEither<AppException, BaseResponse> updatePassword(Map<String, dynamic> body) {
    return callApi(apiCall: () => _authApi.updatePassword(body));
  }

  @override
  TaskEither<AppException, BaseResponse<AppUser>> verifyOTP(Map<String, dynamic> body) {
    return callApi(apiCall: () => _authApi.verifyOTP(body));
  }

  @override
  TaskEither<AppException, BaseResponse> deletePermanentUser(String password) {
    return callApi(apiCall: () => _authApi.deletePermanentUser(password));
  }

  @override
  TaskEither<AppException, BaseResponse> deleteAccount() {
    return callApi(apiCall: () => _authApi.deleteAccount());
  }
}
