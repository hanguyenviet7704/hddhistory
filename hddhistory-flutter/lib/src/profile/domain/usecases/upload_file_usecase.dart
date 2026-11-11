part of '../../profile.dart';

class UploadFileParams {
  final MultipartFile file;
  final String key;
  final String prefix;
  final String folder;

  UploadFileParams({
    required this.file,
    required this.key,
    required this.prefix,
    required this.folder,
  });
}

@lazySingleton
class UploadFileUseCase implements BaseUseCase<UploadFileParams, UploadEntity> {
  final IUploadRepository _repository;

  UploadFileUseCase(this._repository);

  @override
  TaskEither<AppException, UploadEntity> call(UploadFileParams params) {
    return _repository.uploadFile(params);
  }
}
