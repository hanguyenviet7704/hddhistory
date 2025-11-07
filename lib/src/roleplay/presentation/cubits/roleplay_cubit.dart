part of '../../roleplay.dart';

@lazySingleton
class RoleplayCubit extends Cubit<RoleplayState> with CubitUseCaseHandlerMixin<RoleplayState> {
  final GetRoleplayLearningItemUseCase _getLearningItemUseCase;

  RoleplayCubit(
    this._getLearningItemUseCase,
  ) : super(RoleplayState.initial());

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: RoleplayStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: RoleplayStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }
}
