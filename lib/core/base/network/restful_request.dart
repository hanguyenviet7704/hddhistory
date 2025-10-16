part of '../base.dart';

@pragma('vm:entry-point')
Future<BaseResponseList<T>> requestListIsolate<T>({
  required Future<BaseResponseList<T>> Function() apiCall,
}) async {
  BaseResponseList<T> result = await apiCall();
  return result;
}

@pragma('vm:entry-point')
Future<BaseResponse<T>> requestIsolate<T>({
  required Future<BaseResponse<T>> Function() apiCall,
}) async {
  BaseResponse<T> result = await apiCall();
  return result;
}

mixin RestfulRequestHandlerMixin {
  void _showErrorMessage(Object e, StackTrace stackTrace) {
    AppService.instance.appTrackingService.trackError(e, errorType: 'RestfulRequestHandlerMixin', stackTrace: stackTrace);
    if (e is DioException) {
      if (e.response?.statusCode == 401) return;
      DMessage.showMessage(
        type: MessageType.error,
        message: e.response?.data['message'] ?? e.toString(),
      );
      return;
    }

    DMessage.showMessage(
      type: MessageType.error,
      message: e.toString(),
    );
  }

  TaskEither<AppException, BaseResponse<T>> callApi<T>({
    required Future<BaseResponse<T>> Function() apiCall,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        BaseResponse<T> response;
        if (enableIsolate) {
          response = await Isolate.run(apiCall);
          return response;
        }
        response = await apiCall();
        return response;
      },
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        return AppException.unexpected(error.toString());
      },
    );
  }

  TaskEither<AppException, BaseResponseList<T>> callApiList<T>({
    required Future<BaseResponseList<T>> Function() apiCall,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        BaseResponseList<T> response;
        if (enableIsolate) {
          response = await Isolate.run(apiCall);
          return response;
        }
        response = await apiCall();
        return response;
      },
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        return AppException.unexpected(error.toString());
      },
    );
  }

  TaskEither<AppException, T> callApiCustom<T>({
    required Future<T> Function() apiCall,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        T response;
        if (enableIsolate) {
          response = await Isolate.run(apiCall);
          return response;
        }
        response = await apiCall();
        return response;
      },
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        return AppException.unexpected(error.toString());
      },
    );
  }

  TaskEither<AppException, List<T>> callApiListCustom<T>({
    required Future<List<T>> Function() apiCall,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        List<T> response;
        if (enableIsolate) {
          response = await Isolate.run(apiCall);
          return response;
        }
        response = await apiCall();
        return response;
      },
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        return AppException.unexpected(error.toString());
      },
    );
  }

  // ==================== NEW REUSABLE API CALL FUNCTIONS ====================

  /// Enhanced API call with caching and fallback support
  ///
  /// [apiCall] - The API function to execute
  /// [onSuccess] - Optional callback after successful API call (for caching)
  /// [onError] - Optional fallback function when API fails (for cache retrieval)
  /// [enableIsolate] - Run API call in isolate
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, T> executeApiCall<T>({
    required Future<T> Function() apiCall,
    Future<void> Function(T data)? onSuccess,
    Future<T?> Function()? onError,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          T response;
          if (enableIsolate) {
            response = await Isolate.run(apiCall);
          } else {
            response = await apiCall();
          }

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(response);
          }

          return response;
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
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  /// API call with automatic BaseResponse handling, caching and fallback
  ///
  /// [apiCall] - The API function returning `BaseResponse<T>`
  /// [transform] - Transform response data to desired type (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful API call (for caching)
  /// [onError] - Optional fallback function when API fails (for cache retrieval)
  /// [defaultValue] - Default value if response data is null
  /// [enableIsolate] - Run API call in isolate
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, R> callApiWithTransform<T, R>({
    required Future<BaseResponse<T>> Function() apiCall,
    required R Function(T data) transform,
    Future<void> Function(T? data)? onSuccess,
    Future<R?> Function()? onError,
    R? defaultValue,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          BaseResponse<T> response;
          if (enableIsolate) {
            response = await Isolate.run(apiCall);
          } else {
            response = await apiCall();
          }

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(response.data);
          }

          // Transform and return
          if (response.data != null) {
            return transform(response.data as T);
          } else if (defaultValue != null) {
            return defaultValue;
          } else {
            throw Exception('Response data is null and no default value provided');
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
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  /// API call with automatic BaseResponseList handling, caching and fallback
  ///
  /// [apiCall] - The API function returning `BaseResponseList<T>`
  /// [transform] - Transform each item in response data (e.g., model.toEntity())
  /// [onSuccess] - Optional callback after successful API call (for caching)
  /// [onError] - Optional fallback function when API fails (for cache retrieval)
  /// [enableIsolate] - Run API call in isolate
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, List<R>> callApiListWithTransform<T, R>({
    required Future<BaseResponseList<T>> Function() apiCall,
    required R Function(T data) transform,
    Future<void> Function(List<T> data)? onSuccess,
    Future<List<R>?> Function()? onError,
    bool enableIsolate = false,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        try {
          BaseResponseList<T> response;
          if (enableIsolate) {
            response = await Isolate.run(apiCall);
          } else {
            response = await apiCall();
          }

          // Execute success callback (e.g., caching)
          if (onSuccess != null) {
            await onSuccess(response.data);
          }

          // Transform and return
          return response.data.map((item) => transform(item)).toList();
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
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  /// Simple API execution with standardized error handling
  ///
  /// [apiCall] - The API function to execute
  /// [onSuccess] - Optional callback after successful API call
  /// [enableErrorMessages] - Show error messages to user
  TaskEither<AppException, Unit> executeApiAction({
    required Future<void> Function() apiCall,
    Future<void> Function()? onSuccess,
    bool enableErrorMessages = true,
  }) {
    return TaskEither.tryCatch(
      () async {
        await apiCall();

        if (onSuccess != null) {
          await onSuccess();
        }

        return unit;
      },
      (error, stackTrace) {
        if (enableErrorMessages) _showErrorMessage(error, stackTrace);
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }
}
