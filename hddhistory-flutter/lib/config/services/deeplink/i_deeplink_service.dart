part of '../services.dart';

abstract interface class IDeepLinkService {
  Stream<Uri> get uriStream;
  Future<Uri?> getInitialLink();
  Future<Uri?> getLatestLink();
  void dispose();
}
