part of '../../profile.dart';

@LazySingleton(as: IUploadRepository)
class UploadRepository with RestfulRequestHandlerMixin implements IUploadRepository {
  final UploadApi _api;

  UploadRepository(this._api);

  @override
  TaskEither<AppException, UploadEntity> uploadFile(UploadFileParams params) {
    return callApiWithTransform<UploadModel, UploadEntity>(
      apiCall: () => _api.uploadFile(
        params.file,
        params.key,
        params.prefix,
        params.folder,
      ),
      transform: (model) => model.toEntity(),
      defaultValue: UploadEntity(),
    );
  }
}

