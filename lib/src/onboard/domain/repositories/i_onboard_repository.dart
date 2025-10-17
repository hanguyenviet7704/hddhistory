part of '../../onboard.dart';

abstract class IOnboardRepository {
  TaskEither<AppException, OnboardEntity> getOnboard(String id);
  TaskEither<AppException, BasePageBreak<OnboardEntity>> getAllOnboards(
    PageBreakRequest request,
  );
  TaskEither<AppException, OnboardEntity> createOnboard(OnboardEntity entity);
  TaskEither<AppException, OnboardEntity> updateOnboard(OnboardEntity entity);
  TaskEither<AppException, Unit> deleteOnboard(String id);
}
