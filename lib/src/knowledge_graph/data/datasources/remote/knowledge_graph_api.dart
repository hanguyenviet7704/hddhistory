part of '../../../knowledge_graph.dart';

@lazySingleton
@RestApi()
abstract class KnowledgeGraphApi {
  @factoryMethod
  factory KnowledgeGraphApi(@Named(DIKey.appDio) Dio dio) = _KnowledgeGraphApi;

  /// Tìm thực thể theo tên. Server so khớp trên bản tên đã bỏ dấu nên gõ
  /// "tran hung dao" vẫn ra "Trần Hưng Đạo"; `q` rỗng trả về danh sách đầu.
  @GET(AppEndpoint.kgEntities)
  Future<BaseResponse<List<KgEntitySummaryModel>>> searchEntities({
    @Query('q') String? q,
    @Query('limit') int? limit,
  });

  @GET(AppEndpoint.kgEntityById)
  Future<BaseResponse<KgEntityProfileModel>> getEntityProfile(
    @Path('id') String id,
  );

  @GET(AppEndpoint.kgEntityRelated)
  Future<BaseResponse<List<KgRelatedEntityModel>>> getRelatedEntities(
    @Path('id') String id, {
    @Query('maxHops') int? maxHops,
    @Query('limit') int? limit,
  });
}
