

part of '../../home_widget.dart';

@lazySingleton
class HomeWidgetCubit extends Cubit<HomeWidgetState>
    with CubitUseCaseHandlerMixin<HomeWidgetState> {
  final GetHomeWidgetUseCase _getUseCase;
  

  HomeWidgetCubit(
    this._getUseCase,
    
  ) : super(HomeWidgetState.initial());

  void loadHomeWidget(String id) async {
    await runUseCase<HomeWidgetEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: HomeWidgetStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: HomeWidgetStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: HomeWidgetStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  
}


