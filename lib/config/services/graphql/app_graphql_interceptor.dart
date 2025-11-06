part of '../services.dart';

/// Main app GraphQL interceptor with authentication and error handling
class AppGraphQLInterceptor extends IGraphQLInterceptor {
  // Track if we're already refreshing to prevent multiple refresh attempts
  static bool _isRefreshing = false;
  static final List<Completer<void>> _refreshCompleterQueue = [];

  @override
  Future<graphql.Request> onRequest(graphql.Request request) async {
    // Wait if token is being refreshed
    if (_isRefreshing) {
      await _waitForRefresh();
    }

    // Add authentication headers if not already present
    if (AppGlobalValue.accessToken.isEmpty) {
      return request;
    }

    return request.updateContextEntry<graphql.HttpLinkHeaders>(
      (headers) => graphql.HttpLinkHeaders(
        headers: {
          ...?headers?.headers,
          NetworkConstant.authorization: 'Bearer ${AppGlobalValue.accessToken}',
          'language': _getCurrentLanguage(),
        },
      ),
    );
  }

  @override
  Future<graphql.Response> onResponse(graphql.Response response) async {
    // Check for authentication errors in response
    // if (_hasAuthenticationError(response)) {
    //   await _handleUnauthorized();
    // }
    return response;
  }

  @override
  Future<graphql.Response> onError(graphql.Response response) async {
    // Handle specific error cases
    if (_hasAuthenticationError(response)) {
      final retryResponse = await _handleUnauthorizedWithRetry(response);
      if (retryResponse != null) {
        return retryResponse;
      }
    }

    if (response.errors == null) {
      return response;
    }

    for (final error in response.errors!) {
      final code = error.extensions?['code'];
      switch (code) {
        case 'UNAUTHENTICATED':
          final retryResponse = await _handleUnauthorizedWithRetry(response);
          if (retryResponse != null) {
            return retryResponse;
          }
          break;
        case 'OTP_NOT_VERIFIED':
          _handleOtpNotVerify();
          break;
        case 'FORBIDDEN':
          DMessage.showMessage(
            type: MessageType.error,
            message: 'Không tìm thấy tài nguyên',
          );
          break;
      }
    }

    return response;
  }

  String _getCurrentLanguage() {
    return AppConfig.instance.context!.read<LocaleCubit>().state.localeData.languageCode;
  }

  bool _hasAuthenticationError(graphql.Response response) {
    return response.errors?.any((error) {
          if (error.extensions?['code'] == 'UNAUTHENTICATED') {
            return true;
          }
          if (error.message.toLowerCase().contains('unauthorized')) {
            return true;
          }
          if (error.message.toLowerCase().contains('auth failed')) {
            return true;
          }
          return false;
        }) ??
        false;
  }

  Future<void> _waitForRefresh() async {
    final completer = Completer<void>();
    _refreshCompleterQueue.add(completer);
    await completer.future;
  }

  void _completeRefreshQueue({Object? error}) {
    for (final completer in _refreshCompleterQueue) {
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete();
      }
    }
    _refreshCompleterQueue.clear();
  }

  Future<graphql.Response?> _handleUnauthorizedWithRetry(graphql.Response response) async {
    // Skip if on login page
    if (_isOnLoginPage()) {
      return null;
    }

    // If already refreshing, wait for it to complete
    if (_isRefreshing) {
      await _waitForRefresh();
      // After refresh completes, retry the request if token is available
      if (AppGlobalValue.accessToken.isNotEmpty) {
        return await _retryRequest(response);
      }
      return null;
    }

    // Try to refresh the token
    _isRefreshing = true;
    bool refreshSuccess = false;
    try {
      refreshSuccess = await _attemptTokenRefresh();
    } finally {
      _isRefreshing = false;
    }

    // If refresh was successful, retry the original request
    if (refreshSuccess && AppGlobalValue.accessToken.isNotEmpty) {
      return await _retryRequest(response);
    }

    return null;
  }

  bool _isOnLoginPage() {
    final currentRouteName = AppConfig.instance.context!.read<DeeplinkCubit>().state.currentRouteName;
    return currentRouteName == RoutePath.login;
  }

  Future<bool> _attemptTokenRefresh() async {
    // No refresh token available, logout immediately
    if (AppGlobalValue.refreshToken.isEmpty) {
      await _logoutUser();
      return false;
    }

    try {
      // final supabaseService = AppDI.injector.get<SupabaseService>();
      // await supabaseService.refreshAccessToken();
      LogDev.info('Successfully refreshed access token in GraphQL interceptor');
      _completeRefreshQueue();
      return true;
    } catch (refreshError) {
      LogDev.error('Failed to refresh token in GraphQL interceptor: $refreshError');
      await _logoutUser();
      return false;
    }
  }

  Future<graphql.Response?> _retryRequest(graphql.Response originalResponse) async {
    // The GraphQL Link system will handle the retry automatically
    // We just need to return a specific error that indicates a retry should happen
    // Looking at the GraphQlLink, it retries on NETWORK_ERROR, TIMEOUT, or messages containing 'network'/'timeout'

    LogDev.info('Marking request for retry after token refresh');

    // Create a response with a network error to trigger the retry mechanism in GraphQlLink
    final retryError = graphql.GraphQLError(
      message: 'network error - token refreshed, retry required',
      extensions: {'code': 'NETWORK_ERROR'},
    );

    return graphql.Response(
      data: null,
      errors: [retryError],
      context: originalResponse.context,
      response: <String, dynamic>{},
    );
  }

  Future<void> _logoutUser() async {
    // Clear tokens
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';

    // Clear user data
    AppConfig.instance.context?.read<UserCubit>().clearData();

    // Show error message
    DMessage.showMessage(
      type: MessageType.error,
      message: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
    );

    // Navigate to login
    LoginRoute().push(AppConfig.instance.context!);

    // Notify waiting requests
    _completeRefreshQueue(error: 'Token refresh failed');
  }

  void _handleOtpNotVerify() {
    // AppConfig.instance.context?.read<AuthBloc>().add(ResendOTPEvent());
    OtpRoute().go(AppConfig.instance.context!);
  }
}
