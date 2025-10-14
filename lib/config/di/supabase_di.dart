part of 'di.dart';

@module
abstract class SupabaseModule {
  // Provide Supabase URL based on flavor
  @Named(DIKey.supabaseUrl)
  String get supabaseUrl => EnvConstant.supabaseUrl;

  // Provide Supabase Anonymous Key based on flavor
  @Named(DIKey.supabaseAnonKey)
  String get supabaseAnonKey => EnvConstant.supabaseAnonKey;

  @Named(DIKey.googleWebClientId)
  String get googleWebClientId => EnvConstant.googleWebClientId;

  @Named(DIKey.googleIosClientId)
  String get googleIosClientId => EnvConstant.googleIosClientId;

  @Named(DIKey.googleAndroidClientId)
  String get googleAndroidClientId => EnvConstant.googleAndroidClientId;
}
