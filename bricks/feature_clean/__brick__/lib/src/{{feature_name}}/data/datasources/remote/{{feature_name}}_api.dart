{{#has_remote_datasource}}part of '../../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
@RestApi()
abstract class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api {
  @factoryMethod
  factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Api(@Named(DIKey.appDio) Dio dio) = _{{#pascalCase}}{{feature_name}}{{/pascalCase}}Api;

  @GET('/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s')
  Future<BaseResponse<BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<BaseResponse<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Path('id') String id);

  @POST('/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s')
  Future<BaseResponse<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Body() Map<String, dynamic> body);

  @PUT('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<BaseResponse<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/{{#snakeCase}}{{feature_name}}{{/snakeCase}}s'}/{id}')
  Future<BaseResponse<void>> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(@Path('id') String id);
}
{{/has_remote_datasource}}
