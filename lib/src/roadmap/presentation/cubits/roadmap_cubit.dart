part of '../../roadmap.dart';

@lazySingleton
class RoadmapCubit extends Cubit<RoadmapState> with CubitUseCaseHandlerMixin<RoadmapState> {
  final GetAllRoadmapsUseCase _getAllUseCase;
  final GetRoadmapUseCase _getUseCase;
  final CreateRoadmapUseCase _createUseCase;
  final UpdateRoadmapUseCase _updateUseCase;
  final DeleteRoadmapUseCase _deleteUseCase;

  RoadmapCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(RoadmapState.initial());

  void loadAllRoadmaps({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == RoadmapStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<RoadmapEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: RoadmapStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoadmapStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: RoadmapStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadRoadmap(String id) async {
    await runUseCase<RoadmapEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoadmapStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoadmapStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: RoadmapStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createRoadmap(RoadmapEntity entity) async {
    await runUseCase<RoadmapEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: RoadmapStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoadmapStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoadmapStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  void updateRoadmap(RoadmapEntity entity) async {
    await runUseCase<RoadmapEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: RoadmapStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoadmapStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoadmapStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  void deleteRoadmap(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoadmapStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoadmapStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoadmapStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}

