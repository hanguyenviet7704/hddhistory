part of '../services.dart';

/// GraphQL Link with interceptor support and logging
class GraphQlLink extends graphql.Link {
  final List<IGraphQLInterceptor> interceptors;
  final bool enableLogging;
  final int maxRetries;

  GraphQlLink({
    this.interceptors = const [],
    this.enableLogging = kDebugMode,
    this.maxRetries = 3,
  });

  @override
  Stream<graphql.Response> request(
    /// An incoming [Request]
    graphql.Request request, [

    /// Function that invokes the [request] function of
    ///   the next [Link]
    ///
    /// Terminating [Link]s do not call this function.
    graphql.NextLink? forward,
  ]) async* {
    // Apply request interceptors
    var modifiedRequest = request;
    for (final interceptor in interceptors) {
      modifiedRequest = await interceptor.onRequest(modifiedRequest);
    }

    // Log request if enabled
    if (enableLogging) {
      _logRequest(modifiedRequest);
    }

    // Track retry count - store it in variables instead of context
    final retryCount = (modifiedRequest.variables['__retryCount'] as int?) ?? 0;

    // Remove internal variables before forwarding
    final cleanedVariables = Map<String, dynamic>.from(modifiedRequest.variables)..remove('__retryCount');

    final cleanedRequest = graphql.Request(
      operation: modifiedRequest.operation,
      variables: cleanedVariables,
      context: modifiedRequest.context,
    );

    // Forward the request
    await for (var response in forward!(cleanedRequest)) {
      // Log response if enabled
      if (enableLogging) {
        _logResponse(response);
      }

      // Apply response interceptors
      var modifiedResponse = response;

      // Handle errors
      if (response.errors?.isNotEmpty == true) {
        // Apply error interceptors
        for (final interceptor in interceptors) {
          modifiedResponse = await interceptor.onError(modifiedResponse);
        }

        // Check if we should retry
        if (_shouldRetry(modifiedResponse) && retryCount < maxRetries) {
          // Increment retry count
          final retryRequest = graphql.Request(
            operation: modifiedRequest.operation,
            variables: {
              ...modifiedRequest.variables,
              '__retryCount': retryCount + 1,
            },
            context: modifiedRequest.context,
          );

          if (enableLogging) {
            LogDev.info('🔄 GQL-RETRY (${retryCount + 1}/$maxRetries) ───────────────');
          }

          // Retry the request
          yield* this.request(retryRequest, forward);
          return;
        }
      } else {
        // Apply response interceptors for successful responses
        for (final interceptor in interceptors) {
          modifiedResponse = await interceptor.onResponse(modifiedResponse);
        }
      }

      yield modifiedResponse;
    }
  }

  bool _shouldRetry(graphql.Response response) {
    // Retry on network errors or specific error codes
    return response.errors?.any((error) {
          final code = error.extensions?['code'];
          return code == 'NETWORK_ERROR' || code == 'TIMEOUT' || error.message.toLowerCase().contains('network') || error.message.toLowerCase().contains('timeout');
        }) ??
        false;
  }

  void _logRequest(graphql.Request request) {
    LogDev.one('🟢  GQL-REQUEST  ───────────────────────────────');
    LogDev.one('• op   : ${request.operation.operationName}');
    LogDev.one('• query:\n${request.operation.document.toString()}');
    if (request.variables.isNotEmpty) {
      LogDev.one('• vars : ${_pretty(request.variables)}');
    }
  }

  void _logResponse(graphql.Response response) {
    // Get status code if available
    final dynamic context = response.context;
    final status = context.entry()?.statusCode;

    LogDev.one('🟣  GQL-RESPONSE (HTTP $status) ───────────────');
    if (response.data != null) LogDev.one(_pretty(response.data));
    if (response.errors?.isNotEmpty == true) {
      LogDev.one('⚠️  errors:\n${_pretty(response.errors)}');
    }
    LogDev.one('───────────────────────────────────────────');
  }

  /// Format data as pretty JSON string
  String _pretty(dynamic data) {
    if (data == null) return 'null';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
