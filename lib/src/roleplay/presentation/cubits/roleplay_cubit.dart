part of '../../roleplay.dart';

@lazySingleton
class RoleplayCubit extends Cubit<RoleplayState> with CubitUseCaseHandlerMixin<RoleplayState> {
  final GetRoleplayLearningItemUseCase _getLearningItemUseCase;

  RoleplayCubit(
    this._getLearningItemUseCase,
  ) : super(RoleplayState.initial());

  void reset() => emit(RoleplayState.initial());
  void resetIndex() => emit(state.copyWith(currentSectionIndex: 0));

  void loadLearningItem(String id, {BaseMultiLanguage? estimateCompleTime}) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading, isCurrentSectionRevealed: false),
      onFailure: (error) {
        emit(state.copyWith(status: RoleplayStatus.failure, errorMessage: error, isCurrentSectionRevealed: false));
      },
      onSuccess: (item) {
        LearningItemEntity newItem = item.copyWith(estimateCompleTime: estimateCompleTime ?? item.estimateCompleTime);
        emit(state.copyWith(status: RoleplayStatus.success, currentLearningItem: newItem, isCurrentSectionRevealed: false));
      },
    );
  }

  void goToNextSection() {
    final nextIndex = state.currentSectionIndex + 1;
    if (nextIndex >= state.currentLearningItem.sections.length) return;
    emit(state.copyWith(currentSectionIndex: nextIndex, isCurrentSectionRevealed: false));
  }

  void setCurrentSectionRevealed(bool isRevealed) {
    if (state.isCurrentSectionRevealed == isRevealed) return;
    emit(state.copyWith(isCurrentSectionRevealed: isRevealed));
  }
}
