part of '../services.dart';

@lazySingleton
class RestfulService {
  final String apiBaseUrl;
  final String aiServiceBaseUrl;
  final String apiKey;
  final int connectTimeout;
  final int receiveTimeout;

  RestfulService({
    @Named(DIKey.apiBaseUrl) required this.apiBaseUrl,
    @Named(DIKey.aiServiceBaseUrl) required this.aiServiceBaseUrl,
    @Named(DIKey.apiKey) required this.apiKey,
    @Named(DIKey.connectTimeout) this.connectTimeout = 30000,
    @Named(DIKey.receiveTimeout) this.receiveTimeout = 30000,
  });

  Map<String, dynamic> get headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'apiKey': apiKey,
  };

  Map<String, dynamic> get thirdPartyHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// Basic auth token
  /// User: artlexis_app
  /// Password: shzsU3HxLNVyRGRFq2oLRYfKh
  Map<String, dynamic> get aiHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'Authorization': 'Basic ${base64Encode(utf8.encode('artlexis_app:shzsU3HxLNVyRGRFq2oLRYfKh'))}',
  };

  Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        headers: headers,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return dio;
  }

  Dio createAIDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: aiServiceBaseUrl,
        headers: headers,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return dio;
  }

  Dio createDioThirdParty() {
    final dio = Dio(
      BaseOptions(
        headers: aiHeaders,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return dio;
  }
}
