part of '../../../output_practice.dart';

@lazySingleton
@RestApi()
abstract class OutputPracticeApi {
  @factoryMethod
  factory OutputPracticeApi(@Named(DIKey.appDio) Dio dio) = _OutputPracticeApi;

  @GET(AppEndpoint.coursesOutputPracticeMessages)
  Future<BaseResponse<BasePageBreak<OutputPracticeMessageModel>>> getAllOutputPracticeMessages(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesOutputPracticeSectionConversations)
  Future<BaseResponse<OutputPracticeConversationModel>> getOutputPracticeConversation(@Path('sectionId') String sectionId);

  @POST(AppEndpoint.coursesOutputPracticeMessages)
  Future<BaseResponse<OutputPracticeConversationModel>> createOutputPracticeConversation(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.coursesOutputPracticeMessagesSend)
  Future<BaseResponseList<OutputPracticeMessageModel>> sendOutputPracticeMessage(@Body() Map<String, dynamic> body);
}
