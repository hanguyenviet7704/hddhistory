part of 'di.dart';

@module
abstract class NetworkModule {
  @Named(DIKey.baseUrl)
  @lazySingleton
  String get baseUrl => EnvConstant.baseUrl;

  @Named(DIKey.baseUrlStorage)
  @lazySingleton
  String get baseUrlStorage => EnvConstant.baseUrlStorage;

  @Named(DIKey.apiBaseUrl)
  @lazySingleton
  String get apiBaseUrl => EnvConstant.apiBaseUrl;

  @Named(DIKey.graphqlBaseUrl)
  @lazySingleton
  String get graphqlBaseUrl => EnvConstant.graphqlBaseUrl;

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
    return dio;
  }

  @Named(DIKey.aiDio)
  @lazySingleton
  Dio aiDio(IRestfulService networkService, @Named(DIKey.appInterceptor) Interceptor interceptor) {
    final dio = networkService.createAIDio();
    dio.interceptors.add(interceptor);
    return dio;
  }

  @Named(DIKey.thirdPartyDio)
  @lazySingleton
  Dio thirdPartyDio(IRestfulService networkService, @Named(DIKey.thirdPartyInterceptor) Interceptor interceptor) {
    final dio = networkService.createDioThirdParty();
    dio.interceptors.add(interceptor);
    return dio;
  }

  @Named(DIKey.appGraphql)
  @lazySingleton
  GraphQLClient appGraphql(GraphQLService graphqlService) => graphqlService.createGraphQLClient();
}
