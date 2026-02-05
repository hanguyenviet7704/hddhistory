part of '../services.dart';

@LazySingleton(as: IDeepLinkService)
class DeepLinkService implements IDeepLinkService {
  final AppLinks _appLinks;
  DeepLinkService() : _appLinks = AppLinks();

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Future<Uri?> getLatestLink() => _appLinks.getLatestLink();

  @override
  void dispose() => uriStream.drain();
}
