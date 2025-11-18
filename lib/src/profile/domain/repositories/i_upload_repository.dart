part of '../../profile.dart';

abstract class IUploadRepository {
  TaskEither<AppException, UploadEntity> uploadFile(UploadFileParams params);
}

