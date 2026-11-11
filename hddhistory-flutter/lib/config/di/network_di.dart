part of 'di.dart';

@module
abstract class NetworkModule {
  /// Attach the in-app network inspector to a Dio client — DEV flavor only, so
  /// staging/prod never capture request/response data. In-memory only (no disk).
  void _attachDevInspector(Dio dio) {
    if (F.appFlavor == Flavor.dev) {
      dio.interceptors.add(NetworkInspectorInterceptor());
    }
  }

  @Named(DIKey.apiBaseUrl)
  @lazySingleton
  String get apiBaseUrl => EnvConstant.apiBaseUrl;

  @Named(DIKey.socketBaseUrl)
  @lazySingleton
  String get socketBaseUrl => EnvConstant.socketBaseUrl;

  @Named(DIKey.aiServiceBaseUrl)
  @lazySingleton
  String get aiServiceBaseUrl => EnvConstant.aiServiceBaseUrl;

  @Named(DIKey.apiKey)
  @lazySingleton
  String get apiKey => EnvConstant.apiKey;

  @Named(DIKey.connectTimeout)
  int get connectTimeout => int.parse(EnvConstant.connectTimeout);

  @Named(DIKey.receiveTimeout)
  int get receiveTimeout => int.parse(EnvConstant.receiveTimeout);

  @Named(DIKey.appDio)
  @lazySingleton
  Dio appDio(IRestfulService networkService, @Named(DIKey.appInterceptor) Interceptor interceptor) {
    final dio = networkService.createDio();
    dio.interceptors.add(interceptor);
    _attachDevInspector(dio);
    return dio;
  }

  @Named(DIKey.aiDio)
  @lazySingleton
  Dio aiDio(IRestfulService networkService, @Named(DIKey.appInterceptor) Interceptor interceptor) {
    final dio = networkService.createAIDio();
    dio.interceptors.add(interceptor);
    _attachDevInspector(dio);
    return dio;
  }

  @Named(DIKey.thirdPartyDio)
  @lazySingleton
  Dio thirdPartyDio(IRestfulService networkService, @Named(DIKey.thirdPartyInterceptor) Interceptor interceptor) {
    final dio = networkService.createDioThirdParty();
    dio.interceptors.add(interceptor);
    _attachDevInspector(dio);
    return dio;
  }

  @Named(DIKey.appGraphql)
  @lazySingleton
  GraphQLClient appGraphql(GraphQLService graphqlService) => graphqlService.createGraphQLClient();
}
