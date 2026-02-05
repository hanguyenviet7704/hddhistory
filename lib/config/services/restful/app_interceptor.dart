part of '../services.dart';

@LazySingleton(as: Interceptor)
@Named(DIKey.appInterceptor)
class AppInterceptor extends BaseInterceptor {
  final UserCubit _userCubit;
  final LocaleCubit _localeCubit;
  final PageCubit _pageCubit;

  AppInterceptor(
    this._userCubit,
    this._localeCubit,
    this._pageCubit,
  ) : super(prefix: '[App]');

  static const String _retryCountKey = 'retry_count';
  static const int _maxRetryAttempts = 1;

  AuthBloc get _authBloc => AppDI.injector.get<AuthBloc>();

  String get _currentLanguage => _localeCubit.state.localeData.languageCode;

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
    options.headers['lang'] = _currentLanguage;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _handleResponseStatus(response.statusCode);
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final handledUnauthorized = await _tryHandleUnauthorized(err, handler);
    if (handledUnauthorized) return;

    _handleErrorResponses(err);
    await super.onError(err, handler);
  }

  Future<bool> _tryHandleUnauthorized(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != HttpStatus.unauthorized) return false;

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

    final refreshed = await _authBloc.refreshAccessToken();
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

    final currentRouteName = _pageCubit.state.currentRouteName;
    if (currentRouteName == RoutePath.login) {
      return;
    }

    AppService.instance.resetDI();
    _userCubit.clearData();
    _authBloc.add(AuthEvent.clearSession());
    RegisterRoute().go(context);

    DMessage.showMessage(
      type: MessageType.error,
      message: context.text.auth.authSessionHasExpired,
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
