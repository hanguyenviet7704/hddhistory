part of '../services.dart';

abstract interface class IAppEventService {
  Future<void> initialize();
  Future<void> logAppInstall();
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<bool> requestTrackingAuthorization();
}
