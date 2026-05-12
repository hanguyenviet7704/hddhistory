part of '../services.dart';

@LazySingleton(as: Interceptor)
@Named(DIKey.thirdPartyInterceptor)
class ThirdPartyInterceptor extends BaseInterceptor {
  final bool enableLog;
  ThirdPartyInterceptor({@ignoreParam this.enableLog = false})
    : super(
        prefix: '[ThirdParty]',
        error: enableLog,
        responseBody: enableLog,
        responseHeader: enableLog,
        requestBody: enableLog,
        requestHeader: enableLog,
        request: enableLog,
      );

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
