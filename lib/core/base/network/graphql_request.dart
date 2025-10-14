part of '../base.dart';

mixin GraphQLRequestHandlerMixin {
  void _showGraphQLErrorMessage(Object e, [StackTrace? stackTrace]) {
    AppService.instance.appTrackingService.trackError(e, errorType: 'GraphQLRequestHandlerMixin', stackTrace: stackTrace);
    if (e is OperationException) {
      DMessage.showMessage(
        type: MessageType.error,
        message: e.graphqlErrors.isNotEmpty ? e.graphqlErrors.first.message : e.toString(),
      );
      return;
    }

    DMessage.showMessage(
      type: MessageType.error,
      message: e.toString(),
    );
  }

  AppException _handleGraphQLError(Object error, StackTrace stackTrace, bool enableErrorMessages) {
    if (enableErrorMessages) _showGraphQLErrorMessage(error, stackTrace);
    if (error is OperationException) {
      return AppException.fromGraphQLError(error);
    }
    return AppException.unexpected(error.toString());
  }

  /// Generic GraphQL call for BaseResponseList`<T>`
  /// Usage: return callGraphQLList`<RoadmapNode, Query$GetRoadMap>`(
  ///   queryCall: () => graphqlClient.query$GetRoadMap(...),
  ///   dataExtractor: (data) => data?.roadmapTree.toRoadmapNodes() ?? [],
  /// );
  TaskEither<AppException, BaseResponseList<T>> callGraphQLList<T, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required List<T> Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await queryCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
          // return result.exception!;
        }
        final extractedData = dataExtractor(result.parsedData);
        return BaseResponseList(data: extractedData);
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// Generic GraphQL call for BaseResponse`<T>`
  /// Usage: return callGraphQL`<UserProfile, Query$GetMyProfile>`(
  ///   queryCall: () => graphqlClient.query$GetMyProfile(),
  ///   dataExtractor: (data) => data?.myProfile.toUserProfile(),
  /// );
  Future<TaskEither<AppException, BaseResponse<T>>> callGraphQL<T, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required T? Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await queryCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
          // return result.exception!;
        }
        final extractedData = dataExtractor(result.parsedData);
        return BaseResponse(data: extractedData);
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL call for custom return types (not wrapped in BaseResponse)
  /// Usage: return callGraphQLCustom`<List<Item>, Query$GetItems>`(
  ///   queryCall: () => graphqlClient.query$GetItems(),
  ///   dataExtractor: (data) => data?.items.toItems() ?? [],
  /// );
  Future<TaskEither<AppException, T>> callGraphQLCustom<T, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required T Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await queryCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
          // return result.exception!;
        }
        final extractedData = dataExtractor(result.parsedData);
        return extractedData;
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL mutation call for BaseResponse`<T>`
  /// Usage: return callGraphQLMutation`<MutationResult, Mutation$CreateUser>`(
  ///   mutationCall: () => graphqlClient.mutate$CreateUser(...),
  ///   dataExtractor: (data) => data?.createUser.toMutationResult(),
  /// );
  Future<TaskEither<AppException, BaseResponse<T>>> callGraphQLMutation<T, TData>({
    required Future<QueryResult<TData>> Function() mutationCall,
    required T? Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await mutationCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
          // return result.exception!;
        }
        final extractedData = dataExtractor(result.parsedData);
        return BaseResponse(data: extractedData);
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL mutation call for BaseResponseList`<T>`
  /// Usage: return callGraphQLMutationList`<CreatedItem, Mutation$CreateItems>`(
  ///   mutationCall: () => graphqlClient.mutate$CreateItems(...),
  ///   dataExtractor: (data) => data?.createItems.toCreatedItems() ?? [],
  /// );
  Future<TaskEither<AppException, BaseResponseList<T>>> callGraphQLMutationList<T, TData>({
    required Future<QueryResult<TData>> Function() mutationCall,
    required List<T> Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await mutationCall();

        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
          // return left(AppException.fromGraphQLError(result.exception!));
        }

        final extractedData = dataExtractor(result.parsedData);
        return BaseResponseList(data: extractedData);
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// Simplified GraphQL query for cases where you just need the raw data without wrapping
  /// Usage: return callGraphQLRaw`<List<String>, Query$GetTags>`(
  ///   queryCall: () => graphqlClient.query$GetTags(),
  ///   dataExtractor: (data) => data?.tags?.map((e) => e.name).toList() ?? [],
  /// );
  Future<TaskEither<AppException, T>> callGraphQLRaw<T, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required T Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await queryCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
        }
        final extractedData = dataExtractor(result.parsedData);
        return extractedData;
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// Specialized method for GraphQL subscriptions
  /// Usage: return callGraphQLSubscription`<LiveUpdate, Subscription$LiveUpdates>`(
  ///   subscriptionCall: () => graphqlClient.subscribe$LiveUpdates(),
  ///   dataExtractor: (data) => data?.liveUpdate.toLiveUpdate(),
  /// );
  Stream<Either<AppException, T?>> callGraphQLSubscription<T, TData>({
    required Stream<QueryResult<TData>> Function() subscriptionCall,
    required T? Function(TData? parsedData) dataExtractor,
    bool enableErrorMessages = true,
  }) {
    try {
      return subscriptionCall().map((result) {
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!);
          return left(AppException.fromGraphQLError(result.exception!));
        }

        final extractedData = dataExtractor(result.parsedData);
        return right(extractedData);
      });
    } catch (e) {
      return Stream.value(left(AppException.unexpected(e.toString())));
    }
  }

  /// Simple method for boolean mutations (like delete, update status operations)
  /// Usage: return callGraphQLBooleanMutation`<Mutation$DeleteUser>`(
  ///   mutationCall: () => graphqlClient.mutate$DeleteUser(userId: id),
  /// );
  Future<TaskEither<AppException, bool>> callGraphQLBooleanMutation<TData>({
    required Future<QueryResult<TData>> Function() mutationCall,
    bool enableErrorMessages = true,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final result = await mutationCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
        }
        return true;
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }
}
