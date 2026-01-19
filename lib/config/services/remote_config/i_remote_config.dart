part of '../services.dart';

abstract interface class IRemoteConfigService {
  AppVersionConfigEntity get appVersionConfigModel;
  AppFunctionEntity get appFunctionModel;
  PaywallConfigEntity get paywallConfigModel;
  Future<void> initialize();
  Future<bool> shouldForceUpdate();
}
