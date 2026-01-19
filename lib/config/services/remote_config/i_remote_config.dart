part of '../services.dart';

abstract interface class IRemoteConfigService {
  String get latestAndroidVersion;
  String get latestIosVersion;
  bool get forceUserUpdate;
  AppVersionConfigEntity get appVersionConfigModel;
  AppFunctionEntity get appFunctionModel;
  Future<void> initialize();
  Future<bool> shouldForceUpdate();
}
