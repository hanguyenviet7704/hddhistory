part of '../services.dart';

abstract interface class IRemoteConfigService {
  AppVersionConfigEntity get appVersionConfig;
  AppFunctionEntity get appFunction;
  CourseConfigEntity get courseConfig;
  PaywallConfigEntity get paywallConfig;
  Future<void> initialize();
  Future<bool> shouldForceUpdate();
}
