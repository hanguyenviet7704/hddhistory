part of '../services.dart';

/// Example: Performance monitoring interceptor
class PerformanceInterceptor extends IGraphQLInterceptor {
  @override
  Future<graphql.Request> onRequest(graphql.Request request) async {
    // Store start time in variables
    return graphql.Request(
      operation: request.operation,
      variables: {
        ...request.variables,
        '__startTime': DateTime.now().millisecondsSinceEpoch,
      },
      context: request.context,
    );
  }

  @override
  Future<graphql.Response> onResponse(graphql.Response response) async {
    final startTime = response.response['__startTime'] as int?;
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      LogDev.data('⏱️  GraphQL operation took ${duration}ms');
    }
    return response;
  }

  @override
  Future<graphql.Response> onError(graphql.Response response) async => response;
}