// ignore_for_file: unused_local_variable

part of '../../auth.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin implements IAuthRepository {
  final AuthApi _authApi;
  final IAuthService _authService;
  final IDeviceInfoService _deviceInfoService;
  AuthRepository(this._authApi, this._authService, this._deviceInfoService);

  @override
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body) {
    return TaskEither.tryCatch(
      () async {
        final userCredential = await _authService.signInWithEmail(
          body['email'] as String,
          body['password'] as String,
        );
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';

        return AuthEntity();
      },
      (error, stackTrace) {
        if (error is FirebaseException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, AuthEntity> loginAnonymous(Map<String, dynamic> body) {
    return callApiWithTransform(
      apiCall: () => _authApi.loginAnonymous(body),
      transform: (response) => response.toEntity(),
      defaultValue: AuthEntity(),
    );
  }

  @override
  TaskEither<AppException, AuthEntity> loginSSOGoogle() {
    return TaskEither.tryCatch(
      () async {
        final userCredential = await _authService.signInWithGoogle();
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';
        AppGlobalValue.accessToken = idToken;

        String deviceId = await _deviceInfoService.deviceToken;
        String deviceName = await _deviceInfoService.deviceName;

        BaseResponse<AuthModel> result = await _authApi.loginProvider({
          "device": {
            "deviceId": deviceId,
            "deviceName": deviceName,
          },
          "provider": "google.com",
        });

        return result.data?.toEntity() ?? AuthEntity();
      },
      (error, stackTrace) {
        if (error is FirebaseException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, AuthEntity> loginSSOApple() {
    return TaskEither.tryCatch(
      () async {
        final userCredential = await _authService.signInWithApple();
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';
        AppGlobalValue.accessToken = idToken;
        LogDev.one('idToken: $idToken');

        String deviceId = await _deviceInfoService.deviceToken;
        String deviceName = await _deviceInfoService.deviceName;

        BaseResponse<AuthModel> result = await _authApi.loginProvider({
          "device": {
            "deviceId": deviceId,
            "deviceName": deviceName,
          },
          "provider": "apple.com",
        });

        return result.data?.toEntity() ?? AuthEntity();
      },
      (error, stackTrace) {
        if (error is FirebaseException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, AuthEntity> register(Map<String, dynamic> body) {
    return TaskEither.tryCatch(
      () async {
        final userCredential = await _authService.signUpWithEmail(
          body['email'] as String,
          body['password'] as String,
        );
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';

        return AuthEntity();
      },
      (error, stackTrace) {
        if (error is FirebaseException) {
          return AppException.unauthorized(error.message);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, AuthEntity> refreshToken(Map<String, dynamic> body) {
    return callApiWithTransform(
      apiCall: () => _authApi.refreshToken(body['userId'] as String, body),
      transform: (response) => response.toEntity(),
      defaultValue: AuthEntity(),
    );
  }

  // @override
  // TaskEither<AppException, AuthEntity> forgotPassword(Map<String, dynamic> body) {
  //   return callApiWithTransform<AuthModel, AuthEntity>(
  //     apiCall: () => _authApi.forgotPassword(body),
  //     transform: (response) => response.toEntity(),
  //     defaultValue: AuthEntity(),
  //   );
  // }

  @override
  TaskEither<AppException, BaseResponse> logout() {
    // return callApi(apiCall: () => _authApi.logout());
    return TaskEither.tryCatch(
      () async {
        await _authService.signOut();
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
