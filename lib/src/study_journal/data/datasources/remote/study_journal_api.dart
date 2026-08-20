part of '../../../study_journal.dart';

@lazySingleton
@RestApi()
abstract class StudyJournalApi {
  @factoryMethod
  factory StudyJournalApi(@Named(DIKey.appDio) Dio dio) = _StudyJournalApi;

  @GET(AppEndpoint.coursesUserProgressStudyJournal)
  Future<BaseResponse<StudyJournalMonthModel>> getMonth(
    @Query('month') String month,
    @Query('tzOffset') int tzOffset,
  );

  @GET(AppEndpoint.coursesUserProgressStudyJournalDay)
  Future<BaseResponse<StudyJournalDayDetailModel>> getDay(
    @Query('date') String date,
    @Query('tzOffset') int tzOffset,
  );
}
