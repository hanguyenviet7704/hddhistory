part of '../services.dart';

abstract interface class IRestfulService {
  String get apiBaseUrl;
  String get aiServiceBaseUrl;
  String get apiKey;
  int get connectTimeout;
  int get receiveTimeout;

  Map<String, dynamic> get headers;
  Map<String, dynamic> get thirdPartyHeaders;
  Map<String, dynamic> get aiHeaders;

  Dio createDio();
  Dio createAIDio();
  Dio createDioThirdParty();
}

@LazySingleton(as: IRestfulService)
class RestfulService implements IRestfulService {
  @override
  final String apiBaseUrl;
  @override
  final String aiServiceBaseUrl;
  @override
  final String apiKey;
  @override
  final int connectTimeout;
  @override
  final int receiveTimeout;

  RestfulService({
    @Named(DIKey.apiBaseUrl) required this.apiBaseUrl,
    @Named(DIKey.aiServiceBaseUrl) required this.aiServiceBaseUrl,
    @Named(DIKey.apiKey) required this.apiKey,
    @Named(DIKey.connectTimeout) this.connectTimeout = 30000,
    @Named(DIKey.receiveTimeout) this.receiveTimeout = 30000,
  });

  @override
  Map<String, dynamic> get headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'apiKey': apiKey,
  };

  @override
  Map<String, dynamic> get thirdPartyHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// Basic auth token
  /// User: artlexis_app
  /// Password: shzsU3HxLNVyRGRFq2oLRYfKh
  @override
  Map<String, dynamic> get aiHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'Authorization': 'Basic ${base64Encode(utf8.encode('artlexis_app:shzsU3HxLNVyRGRFq2oLRYfKh'))}',
  };

  @override
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

  @override
  Dio createAIDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: aiServiceBaseUrl,
        headers: aiHeaders,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return dio;
  }

  @override
  Dio createDioThirdParty() {
    final dio = Dio(
      BaseOptions(
        headers: thirdPartyHeaders,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    return dio;
  }
}
