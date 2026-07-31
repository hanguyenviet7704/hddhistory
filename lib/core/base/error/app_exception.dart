part of '../base.dart';

@freezed
sealed class AppException with _$AppException {
  const factory AppException.generic([String? message]) = GenericException;
  const factory AppException.server([String? message]) = ServerException;
  const factory AppException.connection([String? message]) = ConnectionException;
  const factory AppException.database([String? message]) = DatabaseException;
  const factory AppException.cache([String? message]) = CacheException;
  const factory AppException.notFound([String? message]) = NotFoundException;
  const factory AppException.unauthorized([String? message]) = UnauthorizedException;
  const factory AppException.invalidInput([String? message]) = InvalidInputException;
  const factory AppException.unexpected([String? message]) = UnexpectedException;
  const factory AppException.forbidden([String? message]) = ForbiddenException;
  const factory AppException.pending([String? message]) = PendingException;
  const factory AppException.fromDioException(DioException error) = FromDioException;
  const factory AppException.fromGraphQLError(OperationException error) = FromGraphQLErrorException;
}

extension ExceptionExtension on AppException {
  /// Gets the message from any Exception type
  String? get message {
    return switch (this) {
      GenericException(message: final msg) => msg,
      ServerException(message: final msg) => msg,
      ConnectionException(message: final msg) => msg,
      DatabaseException(message: final msg) => msg,
      CacheException(message: final msg) => msg,
      NotFoundException(message: final msg) => msg,
      UnauthorizedException(message: final msg) => msg,
      InvalidInputException(message: final msg) => msg,
      UnexpectedException(message: final msg) => msg,
      ForbiddenException(message: final msg) => msg,
      PendingException(message: final msg) => msg,
      FromDioException(error: final error) => _friendlyDioMessage(error),
      FromGraphQLErrorException(error: final error) => error.toString(),
    };
  }

  /// Network/timeout Dio errors carry a raw, technical `message` (e.g.
  /// "The connection errored: Failed host lookup ...") that must never reach the
  /// user — map them to a friendly, localized line. Other Dio types keep their
  /// message (server responses may carry a meaningful one).
  String? _friendlyDioMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return l10n.common.errorNoInternetConnection;
      default:
        return error.message;
    }
  }

  /// Gets a user-friendly message or a default one
  String get displayMessage {
    return message ?? _defaultMessage;
  }

  String get _defaultMessage {
    return switch (this) {
      GenericException() => 'An error occurred',
      ServerException() => 'Server error occurred',
      ConnectionException() => 'Connection error occurred',
      DatabaseException() => 'Database error occurred',
      CacheException() => 'Cache error occurred',
      NotFoundException() => 'Resource not found',
      UnauthorizedException() => 'Unauthorized access',
      InvalidInputException() => 'Invalid input provided',
      UnexpectedException() => 'An unexpected error occurred',
      ForbiddenException() => 'Access forbidden',
      PendingException() => 'Operation is pending',
      FromDioException() => l10n.common.errorSomethingHappened,
      FromGraphQLErrorException() => 'GraphQL error occurred',
    };
  }
}
