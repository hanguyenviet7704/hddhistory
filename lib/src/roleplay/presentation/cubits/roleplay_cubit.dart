part of '../../roleplay.dart';

@lazySingleton
class RoleplayCubit extends Cubit<RoleplayState> with CubitUseCaseHandlerMixin<RoleplayState> {
  final GetAllRoleplayLearningItemsUseCase _getAllLearningItemsUseCase;
  final GetRoleplayLearningItemUseCase _getLearningItemUseCase;

  RoleplayCubit(
    this._getAllLearningItemsUseCase,
    this._getLearningItemUseCase,
  ) : super(RoleplayState.initial());

  void loadAllLearningItems({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == RoleplayStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<LearningItemEntity>(
      usecase: () => _getAllLearningItemsUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoleplayStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: RoleplayStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoleplayStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: RoleplayStatus.success,
          selectedItem: item,
        ));
      },
    );
  }
}