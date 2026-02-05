part of '../constants.dart';

mixin EnvKey {
  static const String baseUrl = 'BASE_URL';
  static const String baseUrlStorage = 'BASE_URL_STORAGE';
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String graphqlBaseUrl = 'GRAPHQL_BASE_URL';
  static const String aiServiceBaseUrl = 'AI_SERVICE_BASE_URL';
  static const String apiKey = 'API_KEY';
  static const String connectTimeout = 'CONNECT_TIMEOUT';
  static const String receiveTimeout = 'RECEIVE_TIMEOUT';
  static const String appEnv = 'APP_ENVIRONMENT';

  // Supabase Keys
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';

  // Google OAuth Keys
  static const String googleWebClientId = 'GOOGLE_WEB_CLIENT_ID';
  static const String googleIosClientId = 'GOOGLE_IOS_CLIENT_ID';
  static const String googleAndroidClientId = 'GOOGLE_ANDROID_CLIENT_ID';
}

mixin EnvMode {
  static const String dev = 'dev';
  static const String stg = 'stg';
  static const String prod = 'prod';
}

class EnvConstant {
  static const String baseUrl = String.fromEnvironment(EnvKey.baseUrl);
  static const String baseUrlStorage = String.fromEnvironment(EnvKey.baseUrlStorage);
  static const String apiBaseUrl = String.fromEnvironment(EnvKey.apiBaseUrl);
  static const String graphqlBaseUrl = String.fromEnvironment(EnvKey.graphqlBaseUrl);
  static const String aiServiceBaseUrl = String.fromEnvironment(EnvKey.aiServiceBaseUrl);
  static const String apiKey = String.fromEnvironment(EnvKey.apiKey);
  static const String connectTimeout = String.fromEnvironment(EnvKey.connectTimeout);
  static const String receiveTimeout = String.fromEnvironment(EnvKey.receiveTimeout);
  static const String appEnv = String.fromEnvironment(EnvKey.appEnv);

  // Supabase Constants
  static const String supabaseUrl = String.fromEnvironment(EnvKey.supabaseUrl);
  static const String supabaseAnonKey = String.fromEnvironment(EnvKey.supabaseAnonKey);

  // Google OAuth Constants
  static const String googleWebClientId = String.fromEnvironment(EnvKey.googleWebClientId);
  static const String googleIosClientId = String.fromEnvironment(EnvKey.googleIosClientId);
  static const String googleAndroidClientId = String.fromEnvironment(EnvKey.googleAndroidClientId);

  static bool get isDevelopment => appEnv == EnvMode.dev;
  static bool get isStaging => appEnv == EnvMode.stg;
  static bool get isProduction => appEnv == EnvMode.prod;
}
