{{#include_data_layer}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@LazySingleton(as: I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository)
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository{{#has_remote_datasource}} with RestfulRequestHandlerMixin{{/has_remote_datasource}} implements I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  {{#has_remote_datasource}}final {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api _api;
  {{/has_remote_datasource}}{{#has_local_cache}}final {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource _localDataSource;
  {{/has_local_cache}}

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository(
    {{#has_remote_datasource}}this._api{{#has_local_cache}},{{/has_local_cache}}{{/has_remote_datasource}}
    {{#has_local_cache}}this._localDataSource{{/has_local_cache}},
  );

  {{#has_detail}}@override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    {{#has_remote_datasource}}return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),
      transform: (model) => model.toEntity(),
      {{#has_local_cache}}onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),
      onError: () async {
        final cachedModel = await _localDataSource.getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
        return cachedModel?.toEntity();
      },{{/has_local_cache}}
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );{{/has_remote_datasource}}{{^has_remote_datasource}}
    return _missingDataSourceTask('{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository.get{{#pascalCase}}{{entity_name}}{{/pascalCase}}');
    {{/has_remote_datasource}}
  }

  {{/has_detail}}{{#has_list}}@override
  TaskEither<AppException, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    PageBreakRequest request,
  ) {
    {{#has_remote_datasource}}return callApiPageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(request),
      transform: (model) => model.toEntity(),
      {{#has_local_cache}}onSuccess: (pageData) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(pageData.items),
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
      },{{/has_local_cache}}
    );{{/has_remote_datasource}}{{^has_remote_datasource}}
    return _missingDataSourceTask('{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s');
    {{/has_remote_datasource}}
  }

  {{/has_list}}{{#has_create}}@override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    {{#has_remote_datasource}}return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      {{#has_local_cache}}onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),{{/has_local_cache}}
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );{{/has_remote_datasource}}{{^has_remote_datasource}}
    return _missingDataSourceTask('{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}');
    {{/has_remote_datasource}}
  }

  {{/has_create}}{{#has_update}}@override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    {{#has_remote_datasource}}return callApiWithTransform<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      apiCall: () => _api.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      {{#has_local_cache}}onSuccess: (data) async => await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(data ?? {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model()),{{/has_local_cache}}
      defaultValue: {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(),
    );{{/has_remote_datasource}}{{^has_remote_datasource}}
    return _missingDataSourceTask('{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}');
    {{/has_remote_datasource}}
  }

  {{/has_update}}{{#has_delete}}@override
  TaskEither<AppException, Unit> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    {{#has_remote_datasource}}return executeApiAction(
      apiCall: () => _api.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),
      {{#has_local_cache}}onSuccess: () async => await _localDataSource.deleteCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id),{{/has_local_cache}}
    );{{/has_remote_datasource}}{{^has_remote_datasource}}
    return _missingDataSourceTask('{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}');
    {{/has_remote_datasource}}
  }
  {{/has_delete}}

  {{#has_remote_datasource}}// ==================== HELPER METHODS ====================

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
  {{/has_remote_datasource}}

  TaskEither<AppException, T> _missingDataSourceTask<T>(String operation) {
    {{^has_remote_datasource}}{{#has_local_cache}}_localDataSource; // Avoid unused field warnings when only local cache is generated.{{/has_local_cache}}{{/has_remote_datasource}}
    return TaskEither.left(
      AppException.unexpected('$operation is not implemented. Please provide a remote or local data source.'),
    );
  }
}
{{/include_data_layer}}
