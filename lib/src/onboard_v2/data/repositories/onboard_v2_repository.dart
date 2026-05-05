part of '../../onboard_v2.dart';

@LazySingleton(as: IOnboardV2Repository)
class OnboardV2Repository with RestfulRequestHandlerMixin implements IOnboardV2Repository {
  final OnboardV2Api _api;
  final OnboardV2LocalDataSource _localDataSource;

  OnboardV2Repository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, OnboardV2Entity> getOnboardV2(String id) {
    return callApiWithTransform<OnboardV2Model, OnboardV2Entity>(
      apiCall: () => _api.getOnboardV2(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboardV2(data ?? OnboardV2Model()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboardV2(id);
        return cachedModel?.toEntity();
      },
      defaultValue: OnboardV2Entity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<OnboardV2Entity>> getAllOnboardV2s(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<OnboardV2Model, OnboardV2Entity>(
      apiCall: () => _api.getAllOnboardV2s(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async => await _localDataSource.cacheOnboardV2s(pageData.items),
      onError: () async {
        final cachedModels = await _localDataSource.getCachedOnboardV2s();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<OnboardV2Entity>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }
}
