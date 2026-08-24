part of '../../community.dart';

/// Drives the compose screen.
///
/// A factory, so a discarded draft dies with the screen instead of reappearing
/// the next time the composer opens.
@injectable
class CommunityComposeCubit extends Cubit<CommunityComposeState>
    with CubitUseCaseHandlerMixin<CommunityComposeState> {
  final CreateCommunityPostUseCase _createPostUseCase;
  final GetCommunityTopicsUseCase _getTopicsUseCase;
  final UploadFileUseCase _uploadFileUseCase;

  CommunityComposeCubit(
    this._createPostUseCase,
    this._getTopicsUseCase,
    this._uploadFileUseCase,
  ) : super(CommunityComposeState.initial());

  static const int maxImages = 4;

  Future<void> loadTopics() async {
    final result = await _getTopicsUseCase().run();

    result.fold(
      // The group picker is optional, so a failed list just means the reader
      // posts without a group rather than being blocked.
      (_) {},
      (topics) => emit(
        state.copyWith(topics: [...topics.following, ...topics.all]),
      ),
    );
  }

  void setBody(String body) => emit(state.copyWith(body: body));

  void setTopic(String? topicId) => emit(state.copyWith(topicId: topicId));

  void attachCourse({required String courseId, required String title}) {
    emit(state.copyWith(attachedCourseId: courseId, attachedCourseTitle: title));
  }

  void removeAttachedCourse() {
    emit(state.copyWith(attachedCourseId: null, attachedCourseTitle: null));
  }

  /// Uploads the picked file to R2 and keeps the returned URL.
  ///
  /// The URL, not the object key: unlike the import flow (where the API fetches
  /// the file back out of R2 itself), a post's images are only ever displayed,
  /// so the client stores what it will render.
  Future<void> addImage(String filePath) async {
    if (state.images.length >= maxImages) return;

    emit(state.copyWith(isUploadingImage: true, errorMessage: null));

    final result = await _uploadFileUseCase(
      UploadFileParams(
        file: MultipartFile.fromFileSync(filePath),
        key: filePath.fileNameFromPath,
        prefix: 'community_',
        folder: 'community',
      ),
    ).run();

    result.fold(
      (exception) => emit(
        state.copyWith(isUploadingImage: false, errorMessage: exception.message),
      ),
      (upload) => emit(
        state.copyWith(
          isUploadingImage: false,
          images: [...state.images, upload.url],
        ),
      ),
    );
  }

  void removeImage(String url) {
    emit(state.copyWith(images: state.images.where((item) => item != url).toList()));
  }

  Future<CommunityPostEntity?> submit() async {
    if (!state.canSubmit) return null;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _createPostUseCase(
      body: state.body.trim(),
      topicId: state.topicId,
      images: state.images,
      attachedCourseId: state.attachedCourseId,
    ).run();

    return result.fold(
      (exception) {
        emit(state.copyWith(isSubmitting: false, errorMessage: exception.message));
        return null;
      },
      (post) {
        emit(state.copyWith(isSubmitting: false));
        return post;
      },
    );
  }
}
