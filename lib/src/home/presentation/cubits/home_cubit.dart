part of '../../home.dart';

@lazySingleton
class HomeCubit extends Cubit<HomeState> with CubitUseCaseHandlerMixin<HomeState> {
  final GetAllSkillsetsUseCase _getAllUseCase;
  final GetSkillsetUseCase _getUseCase;
  final GetUserProgressMyCoursesUseCase _getUserProgressMyCoursesUseCase;

  HomeCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._getUserProgressMyCoursesUseCase,
  ) : super(HomeState.initial());

  void initializeData() async {
    // Load both courses and skillsets
    await Future.wait<void>([
      loadUserProgressCourses(isInit: true),
      loadAllSkillsets(isInit: true),
    ]);
  }

  Future<void> loadAllSkillsets({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.isLoadingSkillsets) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    emit(state.copyWith(isLoadingSkillsets: true));

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
            isLoadingSkillsets: false,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            pageData: pageData,
            isLoadingSkillsets: false,
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
        emit(
          state.copyWith(
            status: HomeStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }

  Future<void> loadUserProgressCourses({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.isLoadingCourses) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.coursesPageData.isLastPage) return;

    emit(state.copyWith(isLoadingCourses: true));

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.coursesPageData.nextPage);

    await runUseCasePageBreak<UserProgressEntity>(
      usecase: () => _getUserProgressMyCoursesUseCase(pageRequest),
      currentPageData: state.coursesPageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: error,
            isLoadingCourses: false,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            coursesPageData: pageData,
            isLoadingCourses: false,
          ),
        );
      },
    );
  }
}
