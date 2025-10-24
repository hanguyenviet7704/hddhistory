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

  @override
  TaskEither<AppException, LearningItemEntity> createLearningItem(
    LearningItemEntity entity,
  ) {
    return callApiWithTransform<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.createLearningItem(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheLearningItem(data ?? LearningItemModel()),
      defaultValue: LearningItemEntity(),
    );
  }

  @override
  TaskEither<AppException, LearningItemEntity> updateLearningItem(
    LearningItemEntity entity,
  ) {
    return callApiWithTransform<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.updateLearningItem(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheLearningItem(data ?? LearningItemModel()),
      defaultValue: LearningItemEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteLearningItem(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteLearningItem(id),
      onSuccess: () async => await _localDataSource.deleteCachedLearningItem(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts LearningItemEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(LearningItemEntity entity) {
    return {
      'id': entity.id,
      'createdBy': entity.createdBy.toJson(),
      'updatedBy': entity.updatedBy.toJson(),
      'keypointId': entity.keypointId,
      'title': entity.title.toJson(),
      'image': entity.image,
      'type': entity.type,
      'questions': entity.questions
          .map(
            (e) => {
              'type': e.type,
              'id': e.id,
              'speechBubble': e.speechBubble,
              'tag': e.tag,
              'document': e.document
                  .map(
                    (doc) => {
                      'id': doc.id,
                      'type': doc.type,
                      'data': {
                        'title': doc.data.title,
                        'content': doc.data.content,
                        'caption': doc.data.caption,
                        'url': doc.data.url,
                        'thumbnail': doc.data.thumbnail,
                      },
                    },
                  )
                  .toList(),
              'explanation': e.explanation,
              'targetArea': e.targetArea,
              'answer': e.answer
                  .map(
                    (a) => {
                      'id': a.id,
                      'correctAnswer': a.correctAnswer,
                    },
                  )
                  .toList(),
              'options': e.options
                  .map(
                    (o) => {
                      'id': o.id,
                      'label': o.label,
                      'value': o.value,
                    },
                  )
                  .toList(),
              'level': e.level,
              'form': e.form,
              'record': e.record,
              'maxDuration': e.maxDuration,
            },
          )
          .toList(),
      'index': entity.index,
      'isSub': entity.isSub,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }
}
