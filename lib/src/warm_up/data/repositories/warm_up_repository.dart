part of '../../warm_up.dart';

@LazySingleton(as: IWarmUpRepository)
class WarmUpRepository with RestfulRequestHandlerMixin implements IWarmUpRepository {
  final WarmUpApi _api;

  WarmUpRepository(this._api);

  @override
  TaskEither<AppException, WarmUpForCourseEntity> getWarmUpForCourse(String courseId) {
    return callApiWithTransform<WarmUpForCourseModel, WarmUpForCourseEntity>(
      apiCall: () => _api.getWarmUpForCourse(courseId),
      transform: (model) => model.toEntity(),
      defaultValue: const WarmUpForCourseEntity(),
      enableErrorMessages: false,
    );
  }
}
