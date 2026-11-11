part of '../../home.dart';

abstract class IHomeRepository {
  TaskEither<AppException, BasePageBreak<CategoryEntity>> getAllCategories(
    PageBreakRequest<CategoryFilterRequest> request,
  );
  TaskEither<AppException, CategoryEntity> getCategory(String id);
  TaskEither<AppException, QuoteEntity> getRandomQuote();
  TaskEither<AppException, List<SuggestedCourseEntity>> getSuggestCourses(int limit);
  TaskEither<AppException, HomeBannerEntity> getHomeBanner();

  TaskEither<AppException, bool> markHomeBannerImpression(String campaignKey);
  TaskEither<AppException, bool> markHomeBannerClick(String campaignKey);

  TaskEither<AppException, HomePopupEntity> getHomePopup();

  TaskEither<AppException, bool> markHomePopupClicked(String campaignKey);
  TaskEither<AppException, bool> markHomePopupImpression(String campaignKey);
}
