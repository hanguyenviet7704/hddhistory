part of '../../lesson.dart';

@lazySingleton
class LessonVoiceCubit extends Cubit<LessonVoiceState> with CubitUseCaseHandlerMixin<LessonVoiceState> {
  final SendVoiceFeedbackUseCase _sendVoiceFeedbackUseCase;
  final SendVoiceFeedbackStreamUseCase _sendVoiceFeedbackStreamUseCase;
  final SendScoreRecordUseCase _sendScoreRecordUseCase;

  LessonVoiceCubit(
    this._sendVoiceFeedbackUseCase,
    this._sendVoiceFeedbackStreamUseCase,
    this._sendScoreRecordUseCase,
  ) : super(LessonVoiceState.initial());

  void sendVoiceFeedback(VoiceFeedbackRequest request) async {
    await runUseCase<VoiceFeedbackEntity>(
      usecase: () => _sendVoiceFeedbackUseCase(request),
      buildLoadingState: () => state.copyWith(status: LessonVoiceStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonVoiceStatus.failure, errorMessage: error));
      },
      onSuccess: (feedback) {
        emit(state.copyWith(status: LessonVoiceStatus.success, voiceFeedback: feedback));
      },
    );
  }

  void sendVoiceFeedbackStream(VoiceFeedbackRequest request) async {
    await runUseCase<ResponseBody>(
      usecase: () => _sendVoiceFeedbackStreamUseCase(request),
      buildLoadingState: () => state.copyWith(status: LessonVoiceStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonVoiceStatus.failure, errorMessage: error));
      },
      onSuccess: (streamResponse) {
        emit(state.copyWith(status: LessonVoiceStatus.success, streamResponse: streamResponse));
      },
    );
  }

  void sendScoreRecord(ScoreRecordRequest request) async {
    await runUseCase<VoiceFeedbackEntity>(
      usecase: () => _sendScoreRecordUseCase(request),
      buildLoadingState: () => state.copyWith(status: LessonVoiceStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonVoiceStatus.failure, errorMessage: error));
      },
      onSuccess: (feedback) {
        emit(state.copyWith(status: LessonVoiceStatus.success, voiceFeedback: feedback));
      },
    );
  }

  void reset() => emit(LessonVoiceState.initial());
}
