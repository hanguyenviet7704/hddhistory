part of '../services.dart';

/// Abstract base class for GraphQL interceptors
abstract interface class IGraphQLInterceptor {
  /// Called before the request is sent
  Future<graphql.Request> onRequest(graphql.Request request);

  /// Called after the response is received
  Future<graphql.Response> onResponse(graphql.Response response);

  /// Called when an error occurs
  Future<graphql.Response> onError(graphql.Response response);
}
