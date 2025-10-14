part of 'repositories.dart';

@LazySingleton(as: IProfileRepository)
class ProfileRepository with RestfulRequestHandlerMixin, GraphQLRequestHandlerMixin implements IProfileRepository {
  final GraphQLClient graphqlClient;
  final ProfileApi profileApi;
  ProfileRepository(@Named(DIKey.appGraphql) this.graphqlClient, this.profileApi);

  @override
  TaskEither<AppException, BaseResponseList<Profile>> getMyProfiles() {
    return callGraphQLList(
      queryCall: () => graphqlClient.query$GetMyProfile(
        Options$Query$GetMyProfile(
          variables: Variables$Query$GetMyProfile(version: '1.0.6'),
        ),
      ),
      dataExtractor: (data) => data?.myProfiles.toProfiles() ?? [],
    );
  }

  @override
  TaskEither<AppException, BaseResponse<ChangeUserProfileIdModel>> changeProfileId(String profileId) {
    return callApi(
      apiCall: () => profileApi.changeProfileId({'p_target_profile_id': profileId}),
    );
  }
}
