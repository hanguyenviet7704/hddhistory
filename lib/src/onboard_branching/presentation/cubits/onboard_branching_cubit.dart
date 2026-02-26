

part of '../../onboard_branching.dart';

@lazySingleton
class OnboardBranchingCubit extends Cubit<OnboardBranchingState>
    with CubitUseCaseHandlerMixin<OnboardBranchingState> {
  final GetOnboardingScenarioBranchingUseCase _getUseCase;
  

  OnboardBranchingCubit(
    this._getUseCase,
    
  ) : super(OnboardBranchingState.initial());

  void loadOnboardingScenarioBranching(String id) async {
    await runUseCase<OnboardingScenarioBranchingEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardBranchingStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardBranchingStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: OnboardBranchingStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  
}


