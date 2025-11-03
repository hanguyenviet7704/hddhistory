part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@LazySingleton(as: I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository)
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository with RestfulRequestHandlerMixin implements I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api _api;
  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource _localDataSource;

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),
      onError: () async {
        final cachedModel = await _localDataSource.getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
        return cachedModel?.toEntity();
      },
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );
  }

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );
  }

  @override
  TaskEither<AppException, Unit> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    return executeApiAction(
      apiCall: () => _api.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),
      onSuccess: () async => await _localDataSource.deleteCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
}
