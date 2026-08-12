part of '../../home.dart';

abstract class IHomeRepository {
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest<SkillsetFilterRequest> request,
  );
  TaskEither<AppException, SkillsetEntity> getSkillset(String id);
  TaskEither<AppException, QuoteEntity> getRandomQuote();
  TaskEither<AppException, List<SuggestedCourseEntity>> getSuggestCourses(int limit);
  TaskEither<AppException, HomeBannerEntity> getHomeBanner();

  TaskEither<AppException, HomePopupEntity> getHomePopup();

  TaskEither<AppException, bool> markHomePopupClicked(String campaignKey);
}
