part of '../../../profile.dart';

@lazySingleton
@RestApi()
abstract class UploadApi {
  @factoryMethod
  factory UploadApi(@Named(DIKey.appDio) Dio dio) = _UploadApi;

  @MultiPart()
  @POST(AppEndpoint.cloudflareUpload)
  Future<BaseResponse<UploadModel>> uploadFile(
    @Part(name: 'file') MultipartFile file,
    @Part(name: 'key') String key,
    @Part(name: 'prefix') String prefix,
    @Part(name: 'folder') String folder,
  );
}
