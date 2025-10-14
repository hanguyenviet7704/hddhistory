part of '../../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
@RestApi()
abstract class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api {
  factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api(@Named(DIKey.appDio) Dio dio) = _{{#pascalCase}}{{feature_name}}{{/pascalCase}}Api;

  @GET('/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s')
  Future<List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();

  @GET('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Path('id') String id);

  @POST('/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s')
  Future<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Body() {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model model);

  @PUT('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    @Path('id') String id,
    @Body() {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model model,
  );

  @DELETE('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<void> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Path('id') String id);
}
