part of '../../progress.dart';

@LazySingleton(as: IContentRequestRepository)
class ContentRequestRepository with RestfulRequestHandlerMixin implements IContentRequestRepository {
  final ContentRequestApi _api;

  ContentRequestRepository(this._api);

  @override
  TaskEither<AppException, UserProgressEntity> createCompletedLevelAdditionalContentRequest(
    Map<String, dynamic> body,
  ) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.createCompletedLevelAdditionalContentRequest(body),
      transform: (model) => model.toEntity(),
      onSuccess: (_) async {},
      onError: () async => null,
      defaultValue: UserProgressEntity(),
    );
  }
}
