part of '../../community.dart';

/// Drives the compose screen.
///
/// A factory, so a discarded draft dies with the screen instead of reappearing
/// the next time the composer opens.
@injectable
class CommunityComposeCubit extends Cubit<CommunityComposeState> with CubitUseCaseHandlerMixin<CommunityComposeState> {
  final CreateCommunityPostUseCase _createPostUseCase;
  final GetCommunityTopicsUseCase _getTopicsUseCase;
  final UploadFileUseCase _uploadFileUseCase;
  final CommunityComposeSeed _seed;

  CommunityComposeCubit(
    this._createPostUseCase,
    this._getTopicsUseCase,
    this._uploadFileUseCase,
    this._seed,
  ) : super(CommunityComposeState.initial());

  /// Picks up whatever a share sheet handed over, once.
  ///
  /// Called from the route so it runs before the first build — an attachment
  /// that appeared a frame after the screen did would read as the composer
  /// grabbing something on its own.
  void applyPendingSeed() {
    final seed = _seed.take();
    if (seed == null) return;

    emit(
      state.copyWith(
        attachedCourseId: seed.courseId,
        attachedCourseTitle: seed.courseTitle,
        attachedCard: seed.card,
        // `?? state.topicId` rather than a plain assignment: a seed with no room
        // (a share from a course page) must not clear one already picked.
        topicId: seed.roomId ?? state.topicId,
      ),
    );
  }

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

  void setSubject(String subject) => emit(state.copyWith(subject: subject));

  void setBody(String body) => emit(state.copyWith(body: body));

  /// Picking a room also closes the picker — leaving it open over the answer
  /// would make the reader dismiss a menu they are done with.
  void setTopic(String? topicId) => emit(state.copyWith(topicId: topicId, isRoomPickerOpen: false));

  void toggleRoomPicker() => emit(state.copyWith(isRoomPickerOpen: !state.isRoomPickerOpen));

  void toggleAnonymous() => emit(state.copyWith(isAnonymous: !state.isAnonymous));

  /// Attaches a saved keypoint card, or refuses when the post is already full.
  ///
  /// Returns false so the screen can show the cap toast: the cubit does not
  /// own a toast, and silently dropping the pick would read as a broken button.
  bool attachCard(CommunityAttachedCardEntity card) {
    if (state.attachedCard == null && state.isAttachmentFull) return false;

    emit(state.copyWith(attachedCard: card));
    return true;
  }

  void removeAttachedCard() => emit(state.copyWith(attachedCard: null));

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
  Future<bool> addImage(String filePath) async {
    if (state.images.length >= maxImages || state.isAttachmentFull) return false;

    emit(state.copyWith(isUploadingImage: true, errorMessage: null));

    final result = await _uploadFileUseCase(
      UploadFileParams(
        file: MultipartFile.fromFileSync(filePath),
        key: filePath.fileNameFromPath,
        prefix: 'community_',
        folder: 'community',
      ),
    ).run();

    return result.fold(
      (exception) {
        emit(
          state.copyWith(
            isUploadingImage: false,
            errorMessage: exception.message,
          ),
        );
        return false;
      },
      (upload) {
        emit(
          state.copyWith(
            isUploadingImage: false,
            images: [...state.images, upload.url],
          ),
        );
        return true;
      },
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
      subject: state.subject.trim(),
      topicId: state.topicId,
      images: state.images,
      attachedCourseId: state.attachedCourseId,
      attachedCard: state.attachedCard,
      isAnonymous: state.isAnonymous,
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
