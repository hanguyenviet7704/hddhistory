part of '../../lesson.dart';

@LazySingleton(as: ILessonRepository)
class LessonRepository with RestfulRequestHandlerMixin implements ILessonRepository {
  final LessonApi _api;
  final LessonVoiceApi _voiceApi;
  final LessonVoiceAIApi _voiceStreamAIApi;
  final LessonLocalDataSource _localDataSource;

  LessonRepository(this._api, this._voiceApi, this._voiceStreamAIApi, this._localDataSource);

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
  TaskEither<AppException, VoiceFeedbackEntity> sendVoiceFeedback(VoiceFeedbackRequest request) {
    return callApiWithTransform<VoiceFeedbackModel, VoiceFeedbackEntity>(
      apiCall: () async => await _voiceApi.sendVoiceFeedback(request.toJson()),
      transform: (model) => model.toEntity(),
      defaultValue: VoiceFeedbackEntity(),
    );
  }

  @override
  TaskEither<AppException, ResponseBody> sendVoiceFeedbackStream(VoiceFeedbackRequest request) {
    return TaskEither.tryCatch(
      () async {
        try {
          return await _voiceStreamAIApi.sendVoiceFeedbackStream(request.toJson());
        } catch (e) {
          rethrow;
        }
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, VoiceScoreEntity> sendScoreRecord(Map<String, dynamic> params) {
    return callApiCustom<VoiceScoreModel>(
      apiCall: () async => await _voiceStreamAIApi.sendScoreRecord(params),
    ).map((model) => model.toEntity());
  }

  /// The cap is a SERVER decision, so a failed call must not invent one.
  ///
  /// `defaultValue` is an unlimited access: a paywall that cannot be evaluated must
  /// not be able to lock content away (the same rule the in-lesson wall already
  /// states in code). A network blip therefore costs a few free reads rather than
  /// walling off content the reader is entitled to.
  @override
  TaskEither<AppException, KeypointAccessEntity> getKeypointAccess(String keypointId) {
    return callApiWithTransform<KeypointAccessModel, KeypointAccessEntity>(
      apiCall: () => _api.getKeypointAccess(keypointId),
      transform: (model) => model.toEntity(),
      defaultValue: const KeypointAccessEntity(reason: KeypointAccessReason.unknown),
    );
  }

  /// Refused is the SAFE default here, the opposite of [getKeypointAccess]: a
  /// claim that failed did not spend the ticket, and pretending it succeeded would
  /// hand out the keypoint for free while leaving the reader's ticket unspent for
  /// the next one too.
  @override
  TaskEither<AppException, KeypointClaimEntity> claimKeypointAccess(String keypointId) {
    return callApiWithTransform<KeypointClaimModel, KeypointClaimEntity>(
      apiCall: () => _api.claimKeypointAccess(keypointId),
      transform: (model) => model.toEntity(),
      defaultValue: const KeypointClaimEntity(granted: false),
    );
  }
}
