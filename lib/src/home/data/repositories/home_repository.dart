part of '../../home.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepository with RestfulRequestHandlerMixin implements IHomeRepository {
  final SkillsetApi _skillsetApi;
  final HomeLocalDataSource _localDataSource;

  HomeRepository(this._skillsetApi, this._localDataSource);

  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) {
    return callApiWithTransform<SkillsetModel, SkillsetEntity>(
      apiCall: () => _skillsetApi.getSkillset(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSkillset(data ?? SkillsetModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedSkillset(id);
        return cachedModel?.toEntity();
      },
      defaultValue: SkillsetEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest<SkillsetFilterRequest> request,
  ) {
    return callApiPageBreak<SkillsetModel, SkillsetEntity>(
      apiCall: () => _skillsetApi.getAllSkillsets(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheSkillsets(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedSkillsets();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<SkillsetEntity>(
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
