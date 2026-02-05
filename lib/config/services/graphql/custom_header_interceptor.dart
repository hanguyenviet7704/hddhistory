part of '../services.dart';

/// Example: Custom interceptor for adding custom headers
class CustomHeaderInterceptor extends IGraphQLInterceptor {
  final Map<String, String> headers;

  CustomHeaderInterceptor(this.headers);

  @override
  Future<graphql.Request> onRequest(graphql.Request request) async {
    return request.updateContextEntry<graphql.HttpLinkHeaders>(
      (existingHeaders) => graphql.HttpLinkHeaders(
        headers: {
          ...?existingHeaders?.headers,
          ...headers,
        },
      ),
    );
  }

  @override
  Future<graphql.Response> onResponse(graphql.Response response) async => response;

  @override
  Future<graphql.Response> onError(graphql.Response response) async => response;
}