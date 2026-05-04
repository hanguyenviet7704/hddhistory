part of '../../onboard_v2.dart';

abstract class IOnboardV2Repository {
  TaskEither<AppException, BasePageBreak<OnboardV2Entity>> getAllOnboardV2s(
    PageBreakRequest request,
  );
  TaskEither<AppException, OnboardV2Entity> getOnboardV2(String id);
  
}

