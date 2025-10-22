part of '../services.dart';

class AppInterceptors extends BaseInterceptor {
  AppInterceptors() : super(prefix: '[App]');

  // Track retry attempts to prevent infinite loops
  static const String _retryCountKey = 'retry_count';
  static const int _maxRetryAttempts = 1;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _addHeaders(options);

    super.onRequest(options, handler);
  }

  void _addHeaders(RequestOptions options) {
    // final hasNoToken = AppGlobalValue.accessToken.isEmpty;
    final hasNoAuthHeader = !options.headers.containsKey(NetworkConstant.authorization);

    // if (hasNoToken) {
    //   options.headers['language'] = _getCurrentLanguage();
    //   return;
    // }

    if (hasNoAuthHeader) {
      options.headers[NetworkConstant.authorization] = 'Bearer ${AppGlobalValue.accessToken}';
    }

    options.headers['language'] = _getCurrentLanguage();
  }

  String _getCurrentLanguage() {
    return AppConfig.instance.context!.read<LocaleCubit>().state.localeData.languageCode;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _checkResponseAuthentication(response);
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if this is an authentication error
    if (err.response?.statusCode == HttpStatus.unauthorized) {
      // Log the original 401 error with full details
      if (error) {
        final List<String> messageParts = [
          '$prefix ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
          'Error Type: ${err.type}',
          'Error Message: ${err.message}',
        ];

        if (err.response != null && err.response?.data != null) {
          messageParts.add('Response Data: ${_formatErrorData(err.response?.data)}');
        }

        LogDev.error(messageParts.join('\n'));
      }

      // Get current retry count
      final retryCount = err.requestOptions.extra[_retryCountKey] ?? 0;

      // Only retry if we haven't exceeded max attempts and have a refresh token
      if (retryCount < _maxRetryAttempts && AppGlobalValue.refreshToken.isNotEmpty) {
        try {
          LogDev.info('$prefix Access token expired, attempting to refresh...');

          // Try to refresh the access token
          // final authResponse = await AppDI.injector.get<SupabaseService>().refreshAccessToken();

          // if (authResponse.session != null) {
          //   LogDev.info('$prefix Token refreshed successfully, retrying original request...');

          //   // Update the authorization header with new token
          //   err.requestOptions.headers[NetworkConstant.authorization] = 'Bearer ${AppGlobalValue.accessToken}';

          //   // Increment retry count
          //   err.requestOptions.extra[_retryCountKey] = retryCount + 1;

          //   // Retry the original request with new token
          //   final response = await AppDI.injector.get<Dio>(instanceName: DIKey.appDio).fetch(err.requestOptions);

          //   LogDev.info('$prefix Retry successful after token refresh');

          //   // Return successful response
          //   return handler.resolve(response);
          // } else {
          //   // Refresh failed, handle as unauthorized
          //   LogDev.error('$prefix Token refresh failed: No session returned');
          //   _handleUnauthorized();
          //   return handler.reject(err);
          // }
        } catch (refreshError) {
          LogDev.error('$prefix Failed to refresh token: $refreshError');

          // Both tokens are expired or refresh failed, logout
          _handleUnauthorized();
          return handler.reject(err);
        }
      } else {
        // Max retries exceeded or no refresh token, logout
        if (retryCount >= _maxRetryAttempts) {
          LogDev.warning('$prefix Cannot retry: Max retries exceeded');
        } else {
          LogDev.warning('$prefix Cannot retry: No refresh token available');
        }
        _handleUnauthorized();
        return handler.reject(err);
      }
    }

    // Handle other error responses
    _handleErrorResponses(err);
    await super.onError(err, handler);
  }

  void _checkResponseAuthentication(Response response) {
    final statusCode = response.statusCode;
    switch (statusCode) {
      case HttpStatus.unauthorized:
        // This case is now handled in onError
        break;
      case HttpStatus.gone:
        _handleOtpNotVerify();
        break;
      case HttpStatus.forbidden:
        DMessage.showMessage(type: MessageType.error, message: 'Không tìm thấy tài nguyên');
        break;
    }
  }

  void _handleErrorResponses(DioException err) {
    final statusCode = err.response?.statusCode;
    switch (statusCode) {
      case HttpStatus.unauthorized:
        // Already handled in onError method
        break;
      case HttpStatus.gone:
        _handleOtpNotVerify();
        break;
      case HttpStatus.forbidden:
        DMessage.showMessage(type: MessageType.error, message: 'Không tìm thấy tài nguyên');
        break;
    }
  }

  void _handleUnauthorized() {
    String currentRouteName = AppConfig.instance.context!.read<PageCubit>().state.currentRouteName;
    if (currentRouteName == RoutePath.login) return;

    LoginRoute().push(AppConfig.instance.context!);
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';
    AppService.instance.resetDI();
    AppConfig.instance.context?.read<UserCubit>().clearData();

    // Show error message
    DMessage.showMessage(type: MessageType.error, message: AppConfig.instance.context?.text.authSessionHasExpired ?? '');
  }

  void _handleOtpNotVerify() {
    // AppConfig.instance.context?.read<AuthBloc>().add(ResendOTPEvent());
    OtpRoute().go(AppConfig.instance.context!);
  }

  String _formatErrorData(dynamic data) {
    if (data == null) return 'null';
    if (data is Map || data is List) {
      try {
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        return '\n${encoder.convert(data)}';
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }
}

class ThirdPartyInterceptors extends BaseInterceptor {
  ThirdPartyInterceptors() : super(prefix: '[Third Party]');

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!error) {
      await super.onError(err, handler);
      return;
    }

    _handleErrorResponses(err);
    await super.onError(err, handler);
  }

  void _handleErrorResponses(DioException err) {
    final List<String> messageParts = [
      '$prefix ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    ];

    if (err.response?.statusCode == null) {
      messageParts.addAll([
        'Error Type: ${err.type}',
        'Error Message: ${err.message}',
        'Stack Trace:\n${_formatStackTrace(err.stackTrace)}',
      ]);
    }

    if (err.response != null) {
      messageParts.add(_getDataString(err.response?.data));
    }

    LogDev.fatal(messageParts.join('\n'));
  }
}
