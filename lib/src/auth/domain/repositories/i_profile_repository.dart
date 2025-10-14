part of 'repositories.dart';

abstract interface class IProfileRepository {
  TaskEither<AppException, BaseResponseList<Profile>> getMyProfiles();

  TaskEither<AppException, BaseResponse<ChangeUserProfileIdModel>> changeProfileId(String profileId);
}
