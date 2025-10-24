part of '../../exercise.dart';

@LazySingleton(as: IExerciseRepository)
class ExerciseRepository with RestfulRequestHandlerMixin implements IExerciseRepository {
  final ExerciseApi _api;
  final ExerciseLocalDataSource _localDataSource;

  ExerciseRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) {
    return callApiWithTransform<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.getLearningItem(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheLearningItem(data ?? LearningItemModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedLearningItem(id);
        return cachedModel?.toEntity();
      },
      defaultValue: LearningItemEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.getAllLearningItems(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheLearningItems(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedLearningItems();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<LearningItemEntity>(
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
