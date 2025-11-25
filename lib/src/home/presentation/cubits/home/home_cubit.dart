part of '../../../home.dart';

@lazySingleton
class HomeCubit extends Cubit<HomeState> with CubitUseCaseHandlerMixin<HomeState> {
  final GetAllSkillsetsUseCase _getAllUseCase;
  final GetSkillsetUseCase _getUseCase;

  HomeCubit(
    this._getAllUseCase,
    this._getUseCase,
  ) : super(HomeState.initial());

  bool _isInitialized = false;

  void initializeData() async {
    if (_isInitialized) return;
    _isInitialized = true;
    // Load both courses and skillsets]
    await Future.wait<void>([
      loadAllSkillsets(isInit: true),
      AppDI.injector.get<ProgressCubit>().loadUserProgressMyCourses(isInit: true, recent: true),
    ]);
  }

  void selectSkillsetIndex(int index) => emit(state.copyWith(selectedSkillsetIndex: index));
  void selectSkillset(SkillsetEntity skillset) {
    int skillSetIndex = state.skillsets.indexWhere((s) => s.id == skillset.id);
    if (skillSetIndex == -1) return;
    selectSkillsetIndex(skillSetIndex);
  }

  void selectCourseIndex(int index) {
    emit(state.copyWith(selectedCourseIndex: index));
    AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(courseId: state.currentCourse.id);
  }
  
  void selectCourse(CourseEntity course) {
    int courseIndex = state.currentSkillset.courses.indexWhere((c) => c.id == course.id);
    if (courseIndex == -1) return;
    selectCourseIndex(courseIndex);
  }

  Future<void> loadAllSkillsets({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == HomeStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    emit(state.copyWith(status: HomeStatus.loading));

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<SkillsetEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            pageData: pageData,
          ),
        );
      },
    );
  }

  Future<void> loadSkillset(String id) async {
    await runUseCase<SkillsetEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        updatePageBreakItem(
          currentPageData: state.pageData,
          updatedItem: item,
          getId: (item) => item.id,
          onSuccess: (pageData) => emit(state.copyWith(status: HomeStatus.success, pageData: pageData)),
        );
      },
    );
  }
}
