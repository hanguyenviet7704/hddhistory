part of '../services.dart';

@lazySingleton
class GraphQLService {
  final String graphqlBaseUrl;
  final String apiKey;
  final int connectTimeout;
  final int receiveTimeout;

  GraphQLService({
    @Named('graphqlBaseUrl') required this.graphqlBaseUrl,
    @Named(DIKey.apiKey) required this.apiKey,
    @Named(DIKey.connectTimeout) this.connectTimeout = 30000,
    @Named(DIKey.receiveTimeout) this.receiveTimeout = 30000,
  });

  graphql.GraphQLClient createGraphQLClient() {
    final graphql.HttpLink httpLink = graphql.HttpLink(
      graphqlBaseUrl,
      defaultHeaders: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'apiKey': apiKey,
      },
    );

    // Create link chain with interceptors
    // You can add multiple interceptors as needed:
    // - AppGraphQLInterceptor: Handles authentication and common error scenarios
    // - CustomHeaderInterceptor: Add custom headers to all requests
    // - PerformanceInterceptor: Monitor GraphQL operation performance
    final GraphQlLink graphQlLink = GraphQlLink(
      interceptors: [
        AppGraphQLInterceptor(),
        // CustomHeaderInterceptor({'X-Custom-Header': 'value'}),
        // PerformanceInterceptor(),
      ],
      enableLogging: false,
      maxRetries: 3,
    );

    // Build the link chain: authLink -> graphQlLink -> httpLink
    final graphql.Link link = graphQlLink.concat(httpLink);

    return graphql.GraphQLClient(
      link: link,
      // cache: GraphQLCache(store: HiveStore()),
      cache: graphql.GraphQLCache(),
      defaultPolicies: graphql.DefaultPolicies(
        query: graphql.Policies(
          fetch: graphql.FetchPolicy.networkOnly,
          cacheReread: graphql.CacheRereadPolicy.ignoreOptimisitic,
          error: graphql.ErrorPolicy.all,
        ),
        watchQuery: graphql.Policies(
          fetch: graphql.FetchPolicy.networkOnly,
          cacheReread: graphql.CacheRereadPolicy.ignoreOptimisitic,
          error: graphql.ErrorPolicy.all,
        ),
        mutate: graphql.Policies(
          fetch: graphql.FetchPolicy.networkOnly,
          cacheReread: graphql.CacheRereadPolicy.ignoreOptimisitic,
          error: graphql.ErrorPolicy.all,
        ),
        subscribe: graphql.Policies(
          fetch: graphql.FetchPolicy.networkOnly,
          cacheReread: graphql.CacheRereadPolicy.ignoreOptimisitic,
          error: graphql.ErrorPolicy.all,
        ),
        watchMutation: graphql.Policies(
          fetch: graphql.FetchPolicy.networkOnly,
          cacheReread: graphql.CacheRereadPolicy.ignoreOptimisitic,
          error: graphql.ErrorPolicy.all,
        ),
      ),
    );
  }
}
