part of '../../video_lesson.dart';

@lazySingleton
class VideoLessonCubit extends Cubit<VideoLessonState> with CubitUseCaseHandlerMixin<VideoLessonState> {
  final GetAllUserVideoLessonNotesUseCase _getAllUseCase;
  final GetUserVideoLessonNoteUseCase _getUseCase;
  final GetVideoLearningItemUseCase _getLearningItemUseCase;
  final CreateUserVideoLessonNoteUseCase _createUseCase;
  final UpdateUserVideoLessonNoteUseCase _updateUseCase;
  final DeleteUserVideoLessonNoteUseCase _deleteUseCase;

  VideoLessonCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._getLearningItemUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(VideoLessonState.initial());

  void loadAllUserVideoLessonNotes({bool isInit = false}) async {
    if (!isInit && state.status == VideoLessonStatus.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    final pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<UserVideoLessonNoteEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (pageData) => emit(state.copyWith(status: VideoLessonStatus.success, pageData: pageData)),
    );
  }

  void loadUserVideoLessonNote(String id) async {
    await runUseCase<UserVideoLessonNoteEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (note) => emit(state.copyWith(status: VideoLessonStatus.success, selectedNote: note)),
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (item) => emit(state.copyWith(status: VideoLessonStatus.success, selectedLearningItem: item)),
    );
  }

  void createUserVideoLessonNote(UserVideoLessonNoteEntity entity) async {
    await runUseCase<UserVideoLessonNoteEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        emit(
          state.copyWith(
            status: VideoLessonStatus.success,
            pageData: state.pageData.copyWith(items: updatedItems),
          ),
        );
      },
    );
  }

  void updateUserVideoLessonNote(UserVideoLessonNoteEntity entity) async {
    await runUseCase<UserVideoLessonNoteEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        emit(
          state.copyWith(
            status: VideoLessonStatus.success,
            pageData: state.pageData.copyWith(items: updatedItems),
            selectedNote: updatedItem,
          ),
        );
      },
    );
  }

  void deleteUserVideoLessonNote(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: VideoLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: VideoLessonStatus.failure, errorMessage: error)),
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        emit(
          state.copyWith(
            status: VideoLessonStatus.success,
            pageData: state.pageData.copyWith(items: updatedItems),
          ),
        );
      },
    );
  }
}
