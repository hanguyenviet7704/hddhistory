part of '../../home.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepository with RestfulRequestHandlerMixin implements IHomeRepository {
  final CategoryApi _categoryApi;
  final HomeLocalDataSource _localDataSource;
  final HomeApi _homeApi;

  HomeRepository(this._categoryApi, this._localDataSource, this._homeApi);

  @override
  TaskEither<AppException, CategoryEntity> getCategory(String id) {
    return callApiWithTransform<CategoryModel, CategoryEntity>(
      apiCall: () => _categoryApi.getCategory(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheCategory(data ?? CategoryModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedCategory(id);
        return cachedModel?.toEntity();
      },
      defaultValue: CategoryEntity(),
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

  /// Fire-and-forget: errors must never surface a toast over the rest of
  /// Home, so `enableErrorMessages` is off — unlike the click-reply methods
  /// below, whose failure the reader never sees either way, but which
  /// predate this convention.
  @override
  TaskEither<AppException, bool> markHomeBannerImpression(String campaignKey) {
    return callApiWithTransform<HomeTrackingResultModel, bool>(
      apiCall: () => _homeApi.markHomeBannerImpression({'campaignKey': campaignKey}),
      transform: (model) => model.recorded,
      defaultValue: false,
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, bool> markHomeBannerClick(String campaignKey) {
    return callApiWithTransform<HomeTrackingResultModel, bool>(
      apiCall: () => _homeApi.markHomeBannerClick({'campaignKey': campaignKey}),
      transform: (model) => model.recorded,
      defaultValue: false,
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, HomePopupEntity> getHomePopup() {
    return callApiWithTransform<HomePopupModel, HomePopupEntity>(
      apiCall: () => _homeApi.getHomePopup(),
      transform: (model) => model.toEntity(),
      defaultValue: const HomePopupEntity(),
    );
  }

  @override
  TaskEither<AppException, bool> markHomePopupClicked(String campaignKey) {
    return callApiWithTransform<HomePopupClickResultModel, bool>(
      apiCall: () => _homeApi.markHomePopupClicked({'campaignKey': campaignKey}),
      transform: (model) => model.recorded,
      defaultValue: false,
    );
  }

  @override
  TaskEither<AppException, bool> markHomePopupImpression(String campaignKey) {
    return callApiWithTransform<HomeTrackingResultModel, bool>(
      apiCall: () => _homeApi.markHomePopupImpression({'campaignKey': campaignKey}),
      transform: (model) => model.recorded,
      defaultValue: false,
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<CategoryEntity>> getAllCategories(
    PageBreakRequest<CategoryFilterRequest> request,
  ) {
    return callApiPageBreak<CategoryModel, CategoryEntity>(
      apiCall: () => _categoryApi.getAllCategories(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheCategories(pageData.items);
      },
      onError: () async {
        if (request.filter?.hasFilters ?? false) return null;
        final cachedModels = await _localDataSource.getCachedCategories();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<CategoryEntity>(
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
