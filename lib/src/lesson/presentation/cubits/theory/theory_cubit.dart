part of '../../../lesson.dart';

@lazySingleton
class TheoryCubit extends Cubit<TheoryState> with CubitUseCaseHandlerMixin<TheoryState> {
  final GetLearningItemUseCase _getLearningItemUseCase;

  TheoryCubit(
    this._getLearningItemUseCase,
  ) : super(TheoryState.initial());

  void reset() => emit(TheoryState.initial());

  void setCurrentLearningItem(LearningItemEntity learningItem) {
    emit(
      state.copyWith(
        currentLearningItem: learningItem,
        currentDocumentIndex: 0,
        selectedExplanationOptionKeys: const {},
        hasChecked: false,
        isCorrect: false,
        showExplanation: false,
        errorMessage: null,
      ),
    );
    setTheoryData(learningItem.documents.first);
  }

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
    if (!state.canContinue) return;
    if (state.currentDocumentIndex >= state.currentLearningItem.documents.length - 1) {
      AppDI.injector.get<LessonCubit>().nextLearningItem();
      return;
    }
    emit(
      state.copyWith(
        currentDocumentIndex: state.currentDocumentIndex + 1,
        selectedExplanationOptionKeys: const {},
      ),
    );
    setTheoryData(state.currentDocument);
  }

  void previousDocument() {
    if (state.currentDocumentIndex <= 0) return;
    emit(
      state.copyWith(
        currentDocumentIndex: state.currentDocumentIndex - 1,
        selectedExplanationOptionKeys: const {},
      ),
    );
    setTheoryData(state.currentDocument);
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: TheoryStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: TheoryStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: TheoryStatus.success,
            currentLearningItem: item,
            currentDocumentIndex: 0,
            selectedExplanationOptionKeys: const {},
          ),
        );
        setTheoryData(state.currentDocument);
      },
    );
  }

  void selectExplanationOption({
    required int contentDocumentIndex,
    required String? optionKey,
  }) {
    final nextSelections = Map<int, String>.from(state.selectedExplanationOptionKeys);

    if (optionKey == null || optionKey.isEmpty) {
      nextSelections.remove(contentDocumentIndex);
    } else {
      nextSelections[contentDocumentIndex] = optionKey;
    }

    emit(state.copyWith(selectedExplanationOptionKeys: nextSelections));
  }

  void setTheoryData(DocumentEntity document) {
    AppDI.injector.get<LessonCubit>().setCurrentLessonIndex(state.currentDocumentIndex);
  }
}
