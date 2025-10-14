part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@LazySingleton(as: I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository)
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository with RestfulRequestHandlerMixin implements I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api _api;
  final {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource _localDataSource;

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final model = await _api.get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
          // Cache the result
          await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(model);
          return model.toEntity();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModel = await _localDataSource.getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
          if (cachedModel != null) {
            return cachedModel.toEntity();
          }
          rethrow;
        }
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s() {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final models = await _api.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();
          // Cache the result
          await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(models);
          return models.map((model) => model.toEntity()).toList();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModels = await _localDataSource.getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();
          if (cachedModels.isNotEmpty) {
            return cachedModels.map((model) => model.toEntity()).toList();
          }
          rethrow;
        }
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model(
          id: entity.id,
          name: entity.name,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        );
        final result = await _api.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(model);
        // Cache the newly created item
        await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(result);
        return result.toEntity();
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model(
          id: entity.id,
          name: entity.name,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        );
        final result = await _api.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity.id, model);
        // Update cache with the updated item
        await _localDataSource.cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}(result);
        return result.toEntity();
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, Unit> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
        // Remove from cache after successful deletion
        await _localDataSource.deleteCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(id);
        return unit;
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }
}
