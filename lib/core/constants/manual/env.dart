part of '../constants.dart';

class EnvKey {
  const EnvKey._();
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String socketBaseUrl = 'SOCKET_BASE_URL';
  static const String aiServiceBaseUrl = 'AI_SERVICE_BASE_URL';
  static const String apiKey = 'API_KEY';
  static const String connectTimeout = 'CONNECT_TIMEOUT';
  static const String receiveTimeout = 'RECEIVE_TIMEOUT';
  static const String appEnv = 'APP_ENVIRONMENT';
}

mixin EnvMode {
  static const String dev = 'dev';
  static const String stg = 'stg';
  static const String prod = 'prod';
}

class EnvConstant {
  const EnvConstant._();

  static const String apiBaseUrl = String.fromEnvironment(EnvKey.apiBaseUrl);
  static const String socketBaseUrl = String.fromEnvironment(EnvKey.socketBaseUrl);
  static const String aiServiceBaseUrl = String.fromEnvironment(EnvKey.aiServiceBaseUrl);
  static const String apiKey = String.fromEnvironment(EnvKey.apiKey);
  static const String connectTimeout = String.fromEnvironment(EnvKey.connectTimeout);
  static const String receiveTimeout = String.fromEnvironment(EnvKey.receiveTimeout);
  static const String appEnv = String.fromEnvironment(EnvKey.appEnv);


  static bool get isDevelopment => appEnv == EnvMode.dev;
  static bool get isStaging => appEnv == EnvMode.stg;
  static bool get isProduction => appEnv == EnvMode.prod;
}
