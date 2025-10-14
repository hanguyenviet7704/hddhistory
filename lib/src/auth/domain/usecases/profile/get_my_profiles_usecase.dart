part of '../usecases.dart';

@lazySingleton
class GetMyProfilesUsecase implements UseCaseWithoutParams<BaseResponseList<Profile>> {
  final IProfileRepository _profileRepository;
  GetMyProfilesUsecase(this._profileRepository);

  @override
  TaskEither<AppException, BaseResponseList<Profile>> call() => _profileRepository.getMyProfiles();
}
