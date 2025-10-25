part of '../services.dart';

class AppInterceptors extends BaseInterceptor {
  AppInterceptors() : super(prefix: '[App]');

  static const String _retryCountKey = 'retry_count';
  static const int _maxRetryAttempts = 1;
  static Completer<bool>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _applyHeaders(options);
    super.onRequest(options, handler);
  }

  void _applyHeaders(RequestOptions options) {
    final hasAuthorizationHeader = options.headers.containsKey(NetworkConstant.authorization);
    if (!hasAuthorizationHeader && AppGlobalValue.accessToken.isNotEmpty) {
      options.headers[NetworkConstant.authorization] = 'Bearer ${AppGlobalValue.accessToken}';
    }
    options.headers['language'] = _getCurrentLanguage();
  }

  String _getCurrentLanguage() {
    return AppConfig.instance.context!.read<LocaleCubit>().state.localeData.languageCode;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _handleResponseStatus(response.statusCode);
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final handledUnauthorized = await _tryHandleUnauthorized(err, handler);
    if (handledUnauthorized) {
      return;
    }

    _handleErrorResponses(err);
    await super.onError(err, handler);
  }

  Future<bool> _tryHandleUnauthorized(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != HttpStatus.unauthorized) {
      return false;
    }

    _logUnauthorizedError(err);

    final requestOptions = err.requestOptions;
    final retryCount = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= _maxRetryAttempts) {
      LogDev.warning('$prefix Cannot retry: Max retries exceeded');
      _handleUnauthorized();
      handler.reject(err);
      return true;
    }

    if (AppGlobalValue.refreshToken.isEmpty) {
      LogDev.warning('$prefix Cannot retry: No refresh token available');
      _handleUnauthorized();
      handler.reject(err);
      return true;
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed || AppGlobalValue.accessToken.isEmpty) {
      _handleUnauthorized();
      handler.reject(err);
      return true;
    }

    requestOptions
      ..headers[NetworkConstant.authorization] = 'Bearer ${AppGlobalValue.accessToken}'
      ..extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await _retryUpdatedRequest(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      LogDev.error('$prefix Retry after token refresh failed: ${retryError.message}');
      handler.reject(retryError);
    } catch (retryError) {
      LogDev.error('$prefix Retry after token refresh threw: $retryError');
      handler.reject(err);
    }

    return true;
  }

  Future<Response<dynamic>> _retryUpdatedRequest(RequestOptions requestOptions) {
    final dio = AppDI.injector.get<Dio>(instanceName: DIKey.appDio);
    return dio.fetch(requestOptions);
  }

  Future<bool> _refreshAccessToken() async {
    final existingCompleter = _refreshCompleter;
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    try {
      final refreshToken = AppGlobalValue.refreshToken;
      final userCubit = AppDI.injector.get<UserCubit>();
      final deviceInfoService = AppDI.injector.get<DeviceInfoService>();
      final userId = userCubit.state.user.id;
      String deviceId = await deviceInfoService.deviceToken;
      String deviceName = await deviceInfoService.deviceName;

      if (refreshToken.isEmpty || userId.isEmpty) {
        LogDev.warning('$prefix Token refresh skipped: Missing refresh token or user id');
        complete(false);
        return completer.future;
      }

      LogDev.info('$prefix Access token expired, attempting to refresh...');
      final refreshTokenUsecase = AppDI.injector.get<RefreshTokenUsecase>();

      final result = await refreshTokenUsecase({
        "userId": userId,
        "refreshToken": refreshToken,
        "device": {
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
      }).run();

      final refreshed = result.match(
        (failure) {
          LogDev.error('$prefix Token refresh failed: ${failure.displayMessage}');
          return false;
        },
        (auth) {
          if (auth.token.accessToken.isEmpty) {
            LogDev.error('$prefix Token refresh failed: Empty access token returned');
            return false;
          }

          AppGlobalValue.accessToken = auth.token.accessToken;
          // AppGlobalValue.refreshToken = auth.token.refreshToken;
          userCubit.setAccessToken(auth.token.accessToken);

          LogDev.info('$prefix Token refreshed successfully, retrying original request...');
          return true;
        },
      );

      complete(refreshed);
    } catch (error, stackTrace) {
      LogDev.error('$prefix Failed to refresh token: $error\n$stackTrace');
      complete(false);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  void _handleResponseStatus(int? statusCode) {
    switch (statusCode) {
      case HttpStatus.gone:
        _handleOtpNotVerify();
        break;
      case HttpStatus.forbidden:
        DMessage.showMessage(type: MessageType.error, message: 'Không tìm thấy tài nguyên');
        break;
    }
  }

  void _handleErrorResponses(DioException err) {
    if (err.response?.statusCode == HttpStatus.unauthorized) {
      return;
    }
    _handleResponseStatus(err.response?.statusCode);
  }

  void _handleUnauthorized() {
    final context = AppConfig.instance.context;
    if (context == null) {
      return;
    }

    final currentRouteName = context.read<PageCubit>().state.currentRouteName;
    if (currentRouteName == RoutePath.login) {
      return;
    }

    LoginRoute().push(context);
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';
    AppService.instance.resetDI();
    context.read<UserCubit>().clearData();

    DMessage.showMessage(
      type: MessageType.error,
      message: context.text.authSessionHasExpired,
    );
  }

  void _handleOtpNotVerify() {
    final context = AppConfig.instance.context;
    if (context == null) {
      return;
    }
    OtpRoute().go(context);
  }

  void _logUnauthorizedError(DioException err) {
    if (!error) {
      return;
    }

    final messageParts = [
      '$prefix ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      'Error Type: ${err.type}',
      'Error Message: ${err.message}',
    ];

    final responseData = err.response?.data;
    if (responseData != null) {
      messageParts.add('Response Data: ${_formatErrorData(responseData)}');
    }

    LogDev.error(messageParts.join('\n'));
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
