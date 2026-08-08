part of '../../home.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepository with RestfulRequestHandlerMixin implements IHomeRepository {
  final SkillsetApi _skillsetApi;
  final HomeLocalDataSource _localDataSource;
  final HomeApi _homeApi;

  HomeRepository(this._skillsetApi, this._localDataSource, this._homeApi);

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
  TaskEither<AppException, QuoteEntity> getRandomQuote() {
    return callApiWithTransform<QuoteModel, QuoteEntity>(
      apiCall: () => _homeApi.getRandomQuote(),
      transform: (model) => model.toEntity(),
      defaultValue: const QuoteEntity(),
    );
  }

  @override
  TaskEither<AppException, List<SuggestedCourseEntity>> getSuggestCourses(int limit) {
    return callApiWithTransform<List<SuggestedCourseModel>, List<SuggestedCourseEntity>>(
      apiCall: () => _homeApi.getSuggestCourses(limit),
      transform: (models) => models.map((m) => m.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, HomeBannerEntity> getHomeBanner() {
    return callApiWithTransform<HomeBannerModel, HomeBannerEntity>(
      apiCall: () => _homeApi.getHomeBanner(),
      transform: (model) => model.toEntity(),
      defaultValue: const HomeBannerEntity(),
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
        if (request.filter?.hasFilters ?? false) return null;
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
