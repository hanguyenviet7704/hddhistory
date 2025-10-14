part of '../services.dart';

/// Service class for Supabase operations
/// Handles initialization, authentication, and database operations
@lazySingleton
class SupabaseService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;

  /// Supabase service constructor
  SupabaseService({
    @Named(DIKey.supabaseUrl) required this.supabaseUrl,
    @Named(DIKey.supabaseAnonKey) required this.supabaseAnonKey,
    @Named(DIKey.googleWebClientId) required this.googleWebClientId,
    @Named(DIKey.googleIosClientId) required this.googleIosClientId,
  });

  /// Get the Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Get the current user session
  Session? get currentSession => client.auth.currentSession;

  /// Get the current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  void initialize() {
    Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Sign in with Google
  ///
  /// This uses native Google Sign-In for Android and iOS
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        clientId: Platform.isIOS ? googleIosClientId : null,
        serverClientId: googleWebClientId,
      );

      GoogleSignInAccount? googleUser;

      if (googleSignIn.supportsAuthenticate()) {
        googleUser = await googleSignIn.authenticate();
      } else {
        googleUser = await googleSignIn.attemptLightweightAuthentication();
      }

      if (googleUser == null) {
        throw 'Google sign in was canceled by user';
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found from Google Sign In';
      }

      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.session != null) {
        AppGlobalValue.accessToken = response.session!.accessToken;
        AppGlobalValue.refreshToken = response.session!.refreshToken ?? '';
        LogDev.info('Successfully signed in with Google and saved tokens');
      }

      return response;
    } catch (error) {
      LogDev.error('Error during Google Sign In: $error');
      rethrow;
    }
  }

  /// Sign in with Apple
  ///
  /// This uses native Apple Sign-In for iOS (iOS 13+) following Supabase best practices
  /// Uses nonce-based authentication for enhanced security
  Future<AuthResponse> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      if (!await SignInWithApple.isAvailable()) {
        throw 'Apple Sign In is not available on this device';
      }

      // Generate a random nonce using the Supabase SDK for security
      final rawNonce = client.auth.generateRawNonce();

      // Hash the generated nonce using SHA-256
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Start the sign-in process with the hashed nonce
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce, // Use the hashed nonce for security
      );

      // Check if we received the required credentials
      if (credential.identityToken == null) {
        throw 'No identity token found from Apple Sign In';
      }

      // Sign in with Supabase using the Apple ID token and raw nonce
      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce, // Use the raw nonce (not hashed) for Supabase
      );

      // Save tokens to AppGlobalValue if sign in was successful
      if (response.session != null) {
        AppGlobalValue.accessToken = response.session!.accessToken;
        AppGlobalValue.refreshToken = response.session!.refreshToken ?? '';
        LogDev.info('Successfully signed in with Apple and saved tokens');
      }

      return response;
    } catch (error) {
      LogDev.error('Error during Apple Sign In: $error');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Save tokens to AppGlobalValue if sign in was successful
      if (response.session != null) {
        AppGlobalValue.accessToken = response.session!.accessToken;
        AppGlobalValue.refreshToken = response.session!.refreshToken ?? '';
        LogDev.info('Successfully signed in with password and saved tokens');
      }

      return response;
    } on AuthException catch (error) {
      LogDev.error('Error during password sign in: $error');
      rethrow;
    }
  }

  /// Sign in with magic link (passwordless)
  Future<void> signInWithOtp({
    required String email,
    String? redirectTo,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final AuthResponse response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      // Save tokens to AppGlobalValue if sign up was successful and session exists
      if (response.session != null) {
        AppGlobalValue.accessToken = response.session!.accessToken;
        AppGlobalValue.refreshToken = response.session!.refreshToken ?? '';
        LogDev.info('Successfully signed up and saved tokens');
      }

      return response;
    } catch (error) {
      LogDev.error('Error during sign up: $error');
      rethrow;
    }
  }

  /// Sign out current user
  ///
  /// This will sign out from both Supabase and Google Sign-In if applicable
  Future<void> signOut() async {
    try {
      await client.auth.signOut();

      AppGlobalValue.accessToken = '';
      AppGlobalValue.refreshToken = '';

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
        LogDev.info('Successfully signed out from Google');
      } catch (googleSignOutError) {
        LogDev.warning('Failed to sign out from Google: $googleSignOutError');
      }

      LogDev.info('Apple Sign-In session cleared via Supabase sign out');

      LogDev.info('Successfully signed out from Supabase and cleared tokens');
    } catch (error) {
      LogDev.error('Error during sign out: $error');
      rethrow;
    }
  }

  /// Sign out and clear all session data
  ///
  /// Use this for a complete logout that clears all cached data
  Future<void> signOutAndClearData() async {
    try {
      await signOut();

      // Additional cleanup can be added here if needed
      // For example: clearing local storage, cache, etc.

      LogDev.info('Successfully signed out and cleared all data');
    } catch (error) {
      LogDev.error('Error during sign out and clear data: $error');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Update user data
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  /// Refresh access token using refresh token
  ///
  /// Gets a new access token using the refresh token stored in AppGlobalValue
  /// Updates both access and refresh tokens in AppGlobalValue
  Future<AuthResponse> refreshAccessToken() async {
    try {
      // Get the current refresh token from AppGlobalValue
      final String refreshToken = AppGlobalValue.refreshToken;

      if (refreshToken.isEmpty) {
        throw 'No refresh token available';
      }

      // Refresh the session using the refresh token
      LogDev.one('getting new access token with refresh token: $refreshToken');
      final AuthResponse response = await client.auth.refreshSession();

      if (response.session != null) {
        // Update the tokens in AppGlobalValue
        AppGlobalValue.accessToken = response.session?.accessToken ?? '';
        AppGlobalValue.refreshToken = response.session?.refreshToken ?? '';
        AppConfig.instance.context?.read<UserCubit>().setAuth(
          Auth(
            accessToken: response.session?.accessToken ?? '',
            tokenType: response.session?.tokenType ?? '',
            expiresIn: response.session?.expiresIn ?? 0,
            expiresAt: response.session?.expiresIn ?? 0,
            refreshToken: response.session?.refreshToken ?? '',
            user: AppUser.fromJson(response.user?.toJson() ?? {}),
          ),
        );
        // Clipboard.setData(ClipboardData(text: 'new access token: ${response.session?.accessToken}'));
        LogDev.info('Successfully refreshed access token: ${response.session?.accessToken}');
        return response;
      } else {
        throw 'Failed to refresh token: No session returned';
      }
    } catch (error) {
      LogDev.error('Error refreshing access token: $error');
      rethrow;
    }
  }

  /// Check if access token needs refresh and refresh if necessary
  ///
  /// Returns true if token was refreshed, false if not needed
  Future<bool> refreshTokenIfNeeded() async {
    try {
      // Check if current session is valid and not expired
      if (currentSession != null) {
        final DateTime? expiresAt = currentSession!.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(currentSession!.expiresAt! * 1000) : null;

        if (expiresAt != null) {
          // Check if token expires within the next 5 minutes
          final DateTime now = DateTime.now();
          final Duration timeUntilExpiry = expiresAt.difference(now);

          if (timeUntilExpiry.inMinutes <= 5) {
            LogDev.info('Access token expires soon, refreshing...');
            await refreshAccessToken();
            return true;
          }
        }
      } else if (AppGlobalValue.refreshToken.isNotEmpty) {
        // No current session but we have a refresh token, try to refresh
        LogDev.info('No current session, attempting to refresh with stored token...');
        await refreshAccessToken();
        return true;
      }

      return false;
    } catch (error) {
      LogDev.error('Error checking/refreshing token: $error');
      return false;
    }
  }

  /// Get data from Supabase table
  Future<List<Map<String, dynamic>>> getData({
    required String table,
    String? column,
    dynamic equalTo,
    int? limit,
    int? offset,
    String? orderBy,
    bool ascending = true,
  }) async {
    dynamic query = client.from(table).select();

    if (column != null && equalTo != null) {
      query = query.eq(column, equalTo);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    if (orderBy != null) {
      query = ascending ? query.order(orderBy) : query.order(orderBy, ascending: false);
    }

    return await query;
  }

  /// Insert data into Supabase table
  Future<List<Map<String, dynamic>>> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    return await client.from(table).insert(data).select();
  }

  /// Update data in Supabase table
  Future<List<Map<String, dynamic>>> updateData({
    required String table,
    required Map<String, dynamic> data,
    required String column,
    required dynamic equalTo,
  }) async {
    return await client.from(table).update(data).eq(column, equalTo).select();
  }

  /// Delete data from Supabase table
  Future<List<Map<String, dynamic>>> deleteData({
    required String table,
    required String column,
    required dynamic equalTo,
  }) async {
    return await client.from(table).delete().eq(column, equalTo).select();
  }

  /// Upload file to Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await client.storage.from(bucket).uploadBinary(path, bytes);
    return await client.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 365);
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await client.storage.from(bucket).remove([path]);
  }
}
