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
    if ((e as DioException).response?.statusCode == 401) return;
    DMessage.showMessage(
      type: MessageType.error,
      message: e.response?.data['message'] ?? e.toString(),
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
}
