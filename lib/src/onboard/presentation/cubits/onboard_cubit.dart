part of '../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> with CubitUseCaseHandlerMixin<OnboardState> {
  final GetAllOnboardsUseCase _getAllUseCase;
  final GetOnboardUseCase _getUseCase;
  final CreateOnboardUseCase _createUseCase;
  final UpdateOnboardUseCase _updateUseCase;
  final DeleteOnboardUseCase _deleteUseCase;

  OnboardCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(OnboardState.initial());

  void loadAllOnboards({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == OnboardStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<OnboardEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: OnboardStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadOnboard(String id) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: OnboardStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createOnboard(OnboardEntity entity) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OnboardStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  void updateOnboard(OnboardEntity entity) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OnboardStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  void deleteOnboard(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OnboardStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}
