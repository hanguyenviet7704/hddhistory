part of '../../../lesson.dart';

@lazySingleton
@RestApi()
abstract class LessonApi {
  @factoryMethod
  factory LessonApi(@Named(DIKey.appDio) Dio dio) = _LessonApi;

  @GET(AppEndpoint.coursesLearningItems)
  Future<BaseResponse<BasePageBreak<LearningItemModel>>> getAllLearningItems(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesLearningItemsById)
  Future<BaseResponse<LearningItemModel>> getLearningItem(@Path('id') String id);

  @GET(AppEndpoint.keypointAccessById)
  Future<BaseResponse<KeypointAccessModel>> getKeypointAccess(
    @Path('keypointId') String keypointId,
  );

  @POST(AppEndpoint.keypointAccessClaim)
  Future<BaseResponse<KeypointClaimModel>> claimKeypointAccess(
    @Path('keypointId') String keypointId,
  );
}
