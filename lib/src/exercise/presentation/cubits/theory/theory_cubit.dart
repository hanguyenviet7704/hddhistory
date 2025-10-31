part of '../../../exercise.dart';

@lazySingleton
class TheoryCubit extends Cubit<TheoryState> with CubitUseCaseHandlerMixin<TheoryState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;

  TheoryCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
  ) : super(TheoryState.initial());

  void reset() => emit(TheoryState.initial());

  void checkAnswer() {
    if (state.currentDocument.id == 0) return;

    // Theory documents are always considered correct when checked
    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: true,
        showExplanation: false,
      ),
    );
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  void nextDocument() {
    if (state.currentDocumentIndex >= state.currentLearningItem.documents.length - 1) {
      ReviewTimeRoute().push(AppConfig.instance.context!);
      return;
    }
    emit(state.copyWith(currentDocumentIndex: state.currentDocumentIndex + 1));
    setTheoryData(state.currentDocument);
  }

  void previousDocument() {
    if (state.currentDocumentIndex <= 0) return;
    emit(state.copyWith(currentDocumentIndex: state.currentDocumentIndex - 1));
    setTheoryData(state.currentDocument);
  }

  void loadAllLearningItems({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == TheoryStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<LearningItemEntity>(
      usecase: () => _getAllLearningItemUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: TheoryStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: TheoryStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: TheoryStatus.success, pageData: pageData));
        QuestionEntity dragAndDropLesson = pageData.items[1].questions[2];
        emit(state.copyWith(currentDocumentIndex: 2));
        AppDI.injector.get<DragAndDropCubit>().loadQuestion(dragAndDropLesson);
        loadLearningItem('68f9e14727faeb3760987e14');
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: TheoryStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: TheoryStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: TheoryStatus.success, currentLearningItem: item, currentDocumentIndex: 0));
        setTheoryData(state.currentDocument);
      },
    );
  }


  void setTheoryData(DocumentEntity document) {
  }
}
