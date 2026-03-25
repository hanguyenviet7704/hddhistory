part of '../../output_practice.dart';

@lazySingleton
class OutputPracticeCubit extends Cubit<OutputPracticeState> with CubitUseCaseHandlerMixin<OutputPracticeState> {
  final GetAllOutputPracticeMessagesUseCase _getAllMessagesUseCase;
  final GetOutputPracticeConversationUseCase _getConversationUseCase;
  final CreateOutputPracticeConversationUseCase _createConversationUseCase;
  final SendOutputPracticeMessageUseCase _sendMessageUseCase;

  OutputPracticeCubit(
    this._getAllMessagesUseCase,
    this._getConversationUseCase,
    this._createConversationUseCase,
    this._sendMessageUseCase,
  ) : super(OutputPracticeState.initial());

  void loadAllOutputPracticeMessages({bool isInit = false}) async {
    if (!isInit && state.status == OutputPracticeStatus.loading) return;
    if (!isInit && state.messagesPageData.isLastPage) return;

    final pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.messagesPageData.nextPage);

    await runUseCasePageBreak<OutputPracticeMessageEntity>(
      usecase: () => _getAllMessagesUseCase(pageRequest),
      currentPageData: state.messagesPageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.success,
            messagesPageData: pageData,
          ),
        );
      },
    );
  }

  void loadOutputPracticeConversation(String sectionId) async {
    await runUseCase<OutputPracticeConversationEntity>(
      usecase: () => _getConversationUseCase(sectionId),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.success,
            conversation: item,
          ),
        );
      },
    );
  }

  void createOutputPracticeConversation(Map<String, dynamic> body) async {
    await runUseCase<OutputPracticeConversationEntity>(
      usecase: () => _createConversationUseCase(body),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (newConversation) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.success,
            conversation: newConversation,
          ),
        );
      },
    );
  }

  void sendOutputPracticeMessage(Map<String, dynamic> body) async {
    await runUseCase<List<OutputPracticeMessageEntity>>(
      usecase: () => _sendMessageUseCase(body),
      buildLoadingState: () => state.copyWith(status: OutputPracticeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OutputPracticeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (newMessages) {
        final updatedItems = [...state.messagesPageData.items, ...newMessages];
        final updatedPageData = state.messagesPageData.copyWith(items: updatedItems);
        emit(
          state.copyWith(
            status: OutputPracticeStatus.success,
            messagesPageData: updatedPageData,
          ),
        );
      },
    );
  }
}
