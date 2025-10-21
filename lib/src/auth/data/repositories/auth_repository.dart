part of 'repositories.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin implements IAuthRepository {
  final AuthApi _authApi;
  final AuthService _authService;
  AuthRepository(this._authApi, this._authService);

  @override
  TaskEither<AppException, Auth> login(Map<String, dynamic> body) {
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

        return Auth(
          accessToken: idToken,
          tokenType: 'Bearer',
          expiresIn: 3600, // Default to 1 hour
          expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
          refreshToken: user.refreshToken ?? '',
          user: AppUser(
            id: user.uid,
            email: user.email ?? '',
            isAnonymous: user.isAnonymous,
            userMetadata: UserMetaData(
              email: user.email ?? '',
              username: user.displayName ?? '',
              emailVerified: user.emailVerified,
            ),
            identities: [
              Identity(
                id: user.uid,
                provider: 'email',
                email: user.email ?? '',
                createdAt: user.metadata.creationTime,
                lastSignInAt: user.metadata.lastSignInTime,
              ),
            ],
            createdAt: user.metadata.creationTime,
            lastSignInAt: user.metadata.lastSignInTime,
          ),
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
        final userCredential = await _authService.signInWithGoogle();
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';

        return Auth(
          accessToken: idToken,
          tokenType: 'Bearer',
          expiresIn: 3600, // Default to 1 hour
          expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
          refreshToken: user.refreshToken ?? '',
          user: AppUser(
            id: user.uid,
            email: user.email ?? '',
            isAnonymous: user.isAnonymous,
            userMetadata: UserMetaData(
              email: user.email ?? '',
              username: user.displayName ?? '',
              emailVerified: user.emailVerified,
            ),
            identities: [
              Identity(
                id: user.uid,
                provider: 'google.com',
                email: user.email ?? '',
                createdAt: user.metadata.creationTime,
                lastSignInAt: user.metadata.lastSignInTime,
              ),
            ],
            createdAt: user.metadata.creationTime,
            lastSignInAt: user.metadata.lastSignInTime,
          ),
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
        final userCredential = await _authService.signInWithApple();
        final user = userCredential.user;

        if (user == null) {
          throw AppException.unauthorized('Failed to get user information');
        }

        // Get the ID token for authentication
        final idToken = await user.getIdToken() ?? '';

        return Auth(
          accessToken: idToken,
          tokenType: 'Bearer',
          expiresIn: 3600, // Default to 1 hour
          expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
          refreshToken: user.refreshToken ?? '',
          user: AppUser(
            id: user.uid,
            email: user.email ?? '',
            isAnonymous: user.isAnonymous,
            userMetadata: UserMetaData(
              email: user.email ?? '',
              username: user.displayName ?? '',
              emailVerified: user.emailVerified,
            ),
            identities: [
              Identity(
                id: user.uid,
                provider: 'apple.com',
                email: user.email ?? '',
                createdAt: user.metadata.creationTime,
                lastSignInAt: user.metadata.lastSignInTime,
              ),
            ],
            createdAt: user.metadata.creationTime,
            lastSignInAt: user.metadata.lastSignInTime,
          ),
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

        return Auth(
          accessToken: idToken,
          tokenType: 'Bearer',
          expiresIn: 3600, // Default to 1 hour
          expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
          refreshToken: user.refreshToken ?? '',
          user: AppUser(
            id: user.uid,
            email: user.email ?? '',
            isAnonymous: user.isAnonymous,
            userMetadata: UserMetaData(
              email: user.email ?? '',
              username: user.displayName ?? '',
              emailVerified: user.emailVerified,
            ),
            identities: [
              Identity(
                id: user.uid,
                provider: 'email',
                email: user.email ?? '',
                createdAt: user.metadata.creationTime,
                lastSignInAt: user.metadata.lastSignInTime,
              ),
            ],
            createdAt: user.metadata.creationTime,
            lastSignInAt: user.metadata.lastSignInTime,
          ),
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
