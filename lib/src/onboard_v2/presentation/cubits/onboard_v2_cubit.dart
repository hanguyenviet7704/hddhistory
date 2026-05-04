

part of '../../onboard_v2.dart';

@lazySingleton
class OnboardV2Cubit extends Cubit<OnboardV2State>
    with CubitUseCaseHandlerMixin<OnboardV2State> {
  final GetAllOnboardV2sUseCase _getAllUseCase;
  final GetOnboardV2UseCase _getUseCase;
  

  OnboardV2Cubit(
    this._getAllUseCase,
    this._getUseCase,
    
  ) : super(OnboardV2State.initial());

  void loadAllOnboardV2s({bool isInit = false}) async {
    if (!isInit && state.status == OnboardV2Status.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    final pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<OnboardV2Entity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: OnboardV2Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardV2Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: OnboardV2Status.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadOnboardV2(String id) async {
    await runUseCase<OnboardV2Entity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardV2Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: OnboardV2Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: OnboardV2Status.success,
          selectedItem: item,
        ));
      },
    );
  }

  
}


