

part of '../../output_practice.dart';

@lazySingleton
class OutputPracticeCubit extends Cubit<OutputPracticeState>
    with CubitUseCaseHandlerMixin<OutputPracticeState> {
  final GetAllOutputPracticeConversationsUseCase _getAllUseCase;
  final GetOutputPracticeConversationUseCase _getUseCase;
  final CreateOutputPracticeConversationUseCase _createUseCase;
  final UpdateOutputPracticeConversationUseCase _updateUseCase;
  final DeleteOutputPracticeConversationUseCase _deleteUseCase;
  

  OutputPracticeCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
    
  ) : super(OutputPracticeState.initial());

  void loadAllOutputPracticeConversations({bool isInit = false}) async {
    if (!isInit && state.status == OutputPracticeStatus.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    final pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<OutputPracticeConversationEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OutputPracticeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: OutputPracticeStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadOutputPracticeConversation(String id) async {
    await runUseCase<OutputPracticeConversationEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OutputPracticeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: OutputPracticeStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createOutputPracticeConversation(OutputPracticeConversationEntity entity) async {
    await runUseCase<OutputPracticeConversationEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OutputPracticeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OutputPracticeStatus.success,
          pageData: updatedPageData,
          selectedItem: newItem,
        ));
      },
    );
  }
  void updateOutputPracticeConversation(OutputPracticeConversationEntity entity) async {
    await runUseCase<OutputPracticeConversationEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OutputPracticeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems =
            state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OutputPracticeStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }
  void deleteOutputPracticeConversation(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OutputPracticeStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: OutputPracticeStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
  
}


