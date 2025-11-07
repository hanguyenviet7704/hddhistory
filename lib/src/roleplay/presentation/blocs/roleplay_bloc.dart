part of '../../roleplay.dart';

@lazySingleton
class RoleplayBloc extends Bloc<RoleplayEvent, RoleplayState> with BlocUseCaseHandlerMixin<RoleplayEvent, RoleplayState> {
  final GetAllSectionsUseCase _getAllUseCase;
  final GetSectionUseCase _getUseCase;
  final CreateSectionUseCase _createUseCase;
  final UpdateSectionUseCase _updateUseCase;
  final DeleteSectionUseCase _deleteUseCase;

  RoleplayBloc(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(RoleplayState.initial()) {
    on<_LoadAllSections>(_onLoadAllSections);
    on<_LoadSection>(_onLoadSection);
    on<_CreateSection>(_onCreateSection);
    on<_UpdateSection>(_onUpdateSection);
    on<_DeleteSection>(_onDeleteSection);
  }

  Future<void> _onLoadAllSections(
    _LoadAllSections event,
    Emitter<RoleplayState> emit,
  ) async {
    // Prevent multiple simultaneous loads
    if (!event.isInit && state.status == RoleplayStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!event.isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = event.isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<SectionEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: event.isInit,
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

  Future<void> _onLoadSection(
    _LoadSection event,
    Emitter<RoleplayState> emit,
  ) async {
    await runUseCase<SectionEntity>(
      usecase: () => _getUseCase(event.id),
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

  Future<void> _onCreateSection(
    _CreateSection event,
    Emitter<RoleplayState> emit,
  ) async {
    await runUseCase<SectionEntity>(
      usecase: () => _createUseCase(event.entity),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoleplayStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoleplayStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  Future<void> _onUpdateSection(
    _UpdateSection event,
    Emitter<RoleplayState> emit,
  ) async {
    await runUseCase<SectionEntity>(
      usecase: () => _updateUseCase(event.entity),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoleplayStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoleplayStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  Future<void> _onDeleteSection(
    _DeleteSection event,
    Emitter<RoleplayState> emit,
  ) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(event.id),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: RoleplayStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id.toString() != event.id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: RoleplayStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}

