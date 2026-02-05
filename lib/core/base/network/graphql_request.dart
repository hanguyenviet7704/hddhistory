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
  
  /// Enhanced GraphQL query with caching and fallback support
  ///
  /// Similar to callApiWithTransform but for GraphQL queries.
  ///
  /// [queryCall] - The GraphQL query function
  /// [dataExtractor] - Extract data from GraphQL response
  /// [transform] - Transform extracted data to desired type (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful query (for caching)
  /// [onError] - Optional fallback function when query fails (for cache retrieval)
  /// [defaultValue] - Default value if extracted data is null
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, R> callGraphQLWithTransform<T, R, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required T? Function(TData? parsedData) dataExtractor,
    required R Function(T data) transform,
    Future<void> Function(T? data)? onSuccess,
    Future<R?> Function()? onError,
    R? defaultValue,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          final result = await queryCall();
          if (result.hasException) {
            if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
            if (kDebugMode) throw result.exception!;
          }

          final extractedData = dataExtractor(result.parsedData);

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(extractedData);
          }

          // Transform and return
          if (extractedData != null) {
            return transform(extractedData);
          } else if (defaultValue != null) {
            return defaultValue;
          } else {
            throw Exception('Extracted data is null and no default value provided');
          }
        } catch (e) {
          // Try fallback (e.g., cache retrieval)
          if (onError != null) {
            final fallbackData = await onError();
            if (fallbackData != null) {
              return fallbackData;
            }
          }
          rethrow;
        }
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL query with list transformation, caching and fallback
  ///
  /// [queryCall] - The GraphQL query function
  /// [dataExtractor] - Extract list data from GraphQL response
  /// [transform] - Transform each item (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful query (for caching)
  /// [onError] - Optional fallback function when query fails (for cache retrieval)
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, List<R>> callGraphQLListWithTransform<T, R, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required List<T> Function(TData? parsedData) dataExtractor,
    required R Function(T data) transform,
    Future<void> Function(List<T> data)? onSuccess,
    Future<List<R>?> Function()? onError,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          final result = await queryCall();
          if (result.hasException) {
            if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
            if (kDebugMode) throw result.exception!;
          }

          final extractedData = dataExtractor(result.parsedData);

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(extractedData);
          }

          // Transform and return
          return extractedData.map((item) => transform(item)).toList();
        } catch (e) {
          // Try fallback (e.g., cache retrieval)
          if (onError != null) {
            final fallbackData = await onError();
            if (fallbackData != null) {
              return fallbackData;
            }
          }
          rethrow;
        }
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL mutation with transformation, caching and fallback
  ///
  /// [mutationCall] - The GraphQL mutation function
  /// [dataExtractor] - Extract data from GraphQL response
  /// [transform] - Transform extracted data to desired type (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful mutation (for caching)
  /// [defaultValue] - Default value if extracted data is null
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, R> callGraphQLMutationWithTransform<T, R, TData>({
    required Future<QueryResult<TData>> Function() mutationCall,
    required T? Function(TData? parsedData) dataExtractor,
    required R Function(T data) transform,
    Future<void> Function(T? data)? onSuccess,
    R? defaultValue,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await mutationCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
        }

        final extractedData = dataExtractor(result.parsedData);

        // Execute success callback (e.g., caching)
        if (onSuccess != null) {
          await onSuccess(extractedData);
        }

        // Transform and return
        if (extractedData != null) {
          return transform(extractedData);
        } else if (defaultValue != null) {
          return defaultValue;
        } else {
          throw Exception('Extracted data is null and no default value provided');
        }
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// Simple GraphQL action execution with standardized error handling
  ///
  /// Use for mutations that don't return data (delete, void operations)
  ///
  /// [mutationCall] - The GraphQL mutation function
  /// [onSuccess] - Optional callback after successful mutation
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, Unit> executeGraphQLAction<TData>({
    required Future<QueryResult<TData>> Function() mutationCall,
    Future<void> Function()? onSuccess,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await mutationCall();
        if (result.hasException) {
          if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
          if (kDebugMode) throw result.exception!;
        }

        if (onSuccess != null) {
          await onSuccess();
        }

        return unit;
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }

  /// GraphQL query with automatic BasePageBreak handling, caching and fallback
  ///
  /// For paginated GraphQL queries. Extracts pagination data and transforms items.
  ///
  /// [queryCall] - The GraphQL query function
  /// [dataExtractor] - Extract BasePageBreak data from GraphQL response
  /// [transform] - Transform each item in page data (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful query (for caching)
  /// [onError] - Optional fallback function when query fails (for cache retrieval)
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, BasePageBreak<R>> callGraphQLPageBreak<T, R, TData>({
    required Future<QueryResult<TData>> Function() queryCall,
    required BasePageBreak<T> Function(TData? parsedData) dataExtractor,
    required R Function(T data) transform,
    Future<void> Function(BasePageBreak<T> pageData)? onSuccess,
    Future<BasePageBreak<R>?> Function()? onError,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          final result = await queryCall();
          if (result.hasException) {
            if (enableErrorMessages) _showGraphQLErrorMessage(result.exception!, result.exception!.originalStackTrace);
            if (kDebugMode) throw result.exception!;
          }

          final extractedPageData = dataExtractor(result.parsedData);

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(extractedPageData);
          }

          // Transform and return
          final transformedItems = extractedPageData.items.map((item) => transform(item)).toList();
          return BasePageBreak<R>(
            totalPages: extractedPageData.totalPages,
            currentPage: extractedPageData.currentPage,
            itemsPerPage: extractedPageData.itemsPerPage,
            items: transformedItems,
          );
        } catch (e) {
          // Try fallback (e.g., cache retrieval)
          if (onError != null) {
            final fallbackData = await onError();
            if (fallbackData != null) {
              return fallbackData;
            }
          }
          rethrow;
        }
      },
      (error, stackTrace) => _handleGraphQLError(error, stackTrace, enableErrorMessages),
    );
  }
}
