part of '../../../output_practice.dart';

@lazySingleton
@RestApi()
abstract class OutputPracticeApi {
  @factoryMethod
  factory OutputPracticeApi(@Named(DIKey.appDio) Dio dio) = _OutputPracticeApi;

  @GET(AppEndpoint.coursesOutputPracticeSectionConversations)
  Future<BaseResponse<OutputPracticeConversationModel>> getOutputPracticeConversation(@Path('sectionId') String sectionId);

  @GET(AppEndpoint.coursesOutputPracticeSectionConversationsUsage)
  Future<BaseResponse<OutputPracticeConversationUsageModel>> getOutputPracticeConversationUsage(@Path('sectionId') String sectionId);

  @POST(AppEndpoint.coursesOutputPracticeConversations)
  Future<BaseResponse<OutputPracticeConversationModel>> createOutputPracticeConversation(@Body() Map<String, dynamic> body);

  @GET(AppEndpoint.coursesOutputPracticeMessages)
  Future<BaseResponse<BasePageBreak<OutputPracticeMessageModel>>> getAllOutputPracticeMessages(
    @Queries() OutputPracticeMessagesRequestEntity request,
  );

  @POST(AppEndpoint.coursesOutputPracticeMessagesSend)
  Future<BaseResponseList<OutputPracticeMessageModel>> sendOutputPracticeMessage(@Body() Map<String, dynamic> body);
}
