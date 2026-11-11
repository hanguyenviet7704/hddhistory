part of '../../../data_collect.dart';

@lazySingleton
@RestApi()
abstract class DataCollectApi {
  @factoryMethod
  factory DataCollectApi(@Named(DIKey.appDio) Dio dio) = _DataCollectApi;

  @GET('/data_collects')
  Future<List<UserCollectDataModel>> getAllUserCollectDatas();

  @GET('${'/data_collects'}/{id}')
  Future<UserCollectDataModel> getUserCollectData(@Path('id') String id);

  @POST('/data_collects')
  Future<UserCollectDataModel> createUserCollectData(@Body() UserCollectDataModel model);

  @PUT('${'/data_collects'}/{id}')
  Future<UserCollectDataModel> updateUserCollectData(
    @Path('id') String id,
    @Body() UserCollectDataModel model,
  );

  @DELETE('${'/data_collects'}/{id}')
  Future<void> deleteUserCollectData(@Path('id') String id);
}
