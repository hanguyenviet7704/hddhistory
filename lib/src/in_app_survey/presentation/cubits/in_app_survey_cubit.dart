part of '../../in_app_survey.dart';

@lazySingleton
class InAppSurveyCubit extends Cubit<InAppSurveyState>
    with CubitUseCaseHandlerMixin<InAppSurveyState> {
  final GetInAppSurveyConfigUseCase _getConfigUseCase;
  final CreateInAppSurveyResponseUseCase _createResponseUseCase;

  InAppSurveyCubit(
    this._getConfigUseCase,
    this._createResponseUseCase,
  ) : super(InAppSurveyState.initial());

  void loadInAppSurveyConfig() async {
    await runUseCase<InAppSurveyConfigEntity>(
      usecase: () => _getConfigUseCase(unit),
      buildLoadingState: () => state.copyWith(status: InAppSurveyStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: InAppSurveyStatus.failure, errorMessage: error));
      },
      onSuccess: (config) {
        emit(state.copyWith(status: InAppSurveyStatus.success, config: config));
      },
    );
  }

  void submitSurveyResponse(InAppSurveyResponseEntity entity) async {
    await runUseCase<Unit>(
      usecase: () => _createResponseUseCase(entity),
      buildLoadingState: () => state.copyWith(status: InAppSurveyStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: InAppSurveyStatus.failure, errorMessage: error));
      },
      onSuccess: (_) {
        emit(state.copyWith(status: InAppSurveyStatus.success));
      },
    );
  }
}


