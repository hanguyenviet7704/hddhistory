part of '../../../output_practice.dart';

@lazySingleton
@RestApi()
abstract class OutputPracticeApi {
  @factoryMethod
  factory OutputPracticeApi(@Named(DIKey.appDio) Dio dio) = _OutputPracticeApi;

  @GET('/output_practices')
  Future<BaseResponse<BasePageBreak<OutputPracticeConversationModel>>> getAllOutputPracticeConversations(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/output_practices'}/{id}')
  Future<BaseResponse<OutputPracticeConversationModel>> getOutputPracticeConversation(@Path('id') String id);

  @POST('/output_practices')
  Future<BaseResponse<OutputPracticeConversationModel>> createOutputPracticeConversation(@Body() Map<String, dynamic> body);

  @PUT('${'/output_practices'}/{id}')
  Future<BaseResponse<OutputPracticeConversationModel>> updateOutputPracticeConversation(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/output_practices'}/{id}')
  Future<BaseResponse<void>> deleteOutputPracticeConversation(@Path('id') String id);
}

