part of '../../home.dart';

@lazySingleton
class HomeCubit extends Cubit<HomeState> with CubitUseCaseHandlerMixin<HomeState> {
  final GetAllSkillsetsUseCase _getAllUseCase;
  final GetSkillsetUseCase _getUseCase;
  final CreateSkillsetUseCase _createUseCase;
  final UpdateSkillsetUseCase _updateUseCase;
  final DeleteSkillsetUseCase _deleteUseCase;

  HomeCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(HomeState.initial());

  void loadAllSkillsets({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == HomeStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<SkillsetEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: HomeStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadSkillset(String id) async {
    await runUseCase<SkillsetEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: HomeStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createSkillset(SkillsetEntity entity) async {
    await runUseCase<SkillsetEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: HomeStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  void updateSkillset(SkillsetEntity entity) async {
    await runUseCase<SkillsetEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: HomeStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  void deleteSkillset(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: HomeStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}

