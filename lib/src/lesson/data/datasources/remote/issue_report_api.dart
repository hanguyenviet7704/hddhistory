part of '../../../lesson.dart';

@lazySingleton
@RestApi()
abstract class IssueReportApi {
  @factoryMethod
  factory IssueReportApi(@Named(DIKey.appDio) Dio dio) = _IssueReportApi;

  @POST(AppEndpoint.coursesReports)
  Future<BaseResponse> submitReport(@Body() Map<String, dynamic> body);
}
