part of '../../learning_import.dart';

/// How often the waiting screen asks the server how it is going.
///
/// Three seconds is a compromise: the job takes minutes, so this is far more
/// often than the answer changes, but anything slower makes the stage label lag
/// visibly behind reality and the screen feel stuck.
const _kPollInterval = Duration(seconds: 3);

/// Owns the create-and-wait half of the feature.
///
/// The polling loop lives here rather than in the waiting screen on purpose:
/// the user is explicitly allowed to leave that screen while a job runs, and a
/// timer owned by a disposed widget would either die with it or leak.
@lazySingleton
class LearningImportCubit extends Cubit<LearningImportState>
    with CubitUseCaseHandlerMixin<LearningImportState> {
  final CreateLearningImportUseCase _createImportUseCase;
  final GetLearningImportJobUseCase _getJobUseCase;
  final GetImportQuotaUseCase _getQuotaUseCase;
  final UploadCubit _uploadCubit;

  Timer? _pollTimer;

  LearningImportCubit(
    this._createImportUseCase,
    this._getJobUseCase,
    this._getQuotaUseCase,
    this._uploadCubit,
  ) : super(LearningImportState.initial());

  /// Refreshed every time the sheet opens rather than cached: credits are spent
  /// from other devices too, and a stale "còn 3 lượt" that turns into a
  /// rejection at Confirm is worse than a brief loading state.
  Future<void> loadQuota() => runUseCase<ImportQuotaEntity>(
    usecase: () => _getQuotaUseCase(unit),
    onFailure: (_) {
      // Silent. The sheet still works without a credit count — the server
      // enforces the limit regardless, and blocking the flow on a failed
      // read would deny an import the user is entitled to.
    },
    onSuccess: (quota) => emit(state.copyWith(quota: quota)),
  );

  /// Clears the previous run so the sheet reopens on step one instead of
  /// showing the last import's outcome.
  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    emit(LearningImportState.initial().copyWith(quota: state.quota));
  }

  /// Upload the PDF, then start the run.
  ///
  /// Two steps the user sees as one. The upload is separated because it is the
  /// part that can be slow on mobile data and the part where "it's stuck" has a
  /// different answer.
  Future<void> startPdfImport({
    required File file,
    required String outputLocale,
  }) async {
    emit(state.copyWith(uploading: true, errorCode: null, errorMessage: null));

    final fileName = file.path.split('/').last;

    _uploadCubit.uploadFile(
      UploadFileParams(
        file: MultipartFile.fromFileSync(file.path),
        key: fileName,
        prefix: 'pdf_',
        folder: 'user_import',
      ),
      onSuccess: (result) {
        emit(state.copyWith(uploading: false));
        // The API takes the object KEY, not the CDN url — it fetches the file
        // back out of R2 server-side to hand to the model.
        _create(CreateLearningImportParams(
          fileKey: result.key,
          fileName: fileName,
          outputLocale: outputLocale,
        ));
      },
      onFailure: (error) => emit(state.copyWith(
        uploading: false,
        status: LearningImportStatus.failure,
        errorMessage: error,
      )),
    );
  }

  Future<void> startYoutubeImport({
    required String url,
    required String outputLocale,
  }) {
    emit(state.copyWith(errorCode: null, errorMessage: null));

    return _create(
      CreateLearningImportParams(url: url, outputLocale: outputLocale),
    );
  }

  Future<void> _create(CreateLearningImportParams params) =>
      runUseCase<LearningImportJobEntity>(
        usecase: () => _createImportUseCase(params),
        buildLoadingState: () =>
            state.copyWith(status: LearningImportStatus.loading),
        onFailure: (error) => emit(state.copyWith(
          status: LearningImportStatus.failure,
          errorMessage: error,
        )),
        onSuccess: (job) {
          emit(state.copyWith(status: LearningImportStatus.success, job: job));
          _startPolling(job.id);
        },
      );

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _poll(jobId));
  }

  Future<void> _poll(String jobId) async {
    final result = await _getJobUseCase(jobId).run();

    result.fold(
      // A dropped poll is ignored rather than surfaced: the next tick asks
      // again, and one flaky request must not look like a failed import.
      (_) => null,
      (job) {
        emit(state.copyWith(job: job, errorCode: job.errorCode));

        if (!job.isRunning) {
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      },
    );
  }

  /// Ask the server where the current job stands, right now.
  ///
  /// Called on app resume by [ImportDonePopupHost]. The polling timer does not
  /// survive the app being suspended, so on the way back the job this cubit
  /// holds is exactly as stale as the moment the reader left — and if it
  /// finished while they were away, nothing else would ever notice.
  Future<void> refreshActiveJob() async {
    final job = state.job;
    if (job == null || !job.isRunning) return;

    await _poll(job.id);
    if (state.job?.isRunning ?? false) _startPolling(job.id);
  }

  /// Called when the user comes back to a job started earlier — the flow they
  /// get by leaving the waiting screen and tapping the in-progress card.
  void watchJob(LearningImportJobEntity job) {
    emit(state.copyWith(job: job, status: LearningImportStatus.success));
    if (job.isRunning) _startPolling(job.id);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}

/// The one place an error code becomes a sentence.
///
/// Keyed off the server's code rather than its message so the wording stays
/// localized and stays ours — the API's message is for the admin panel and the
/// logs, not for a learner.
String learningImportErrorText(BuildContext context, String? code) {
  final l10n = context.l10n.learningImport;

  switch (code) {
    case 'PDF_UNREADABLE':
      return l10n.errorPdfUnreadable;
    case 'PDF_TOO_LARGE':
      return l10n.errorPdfTooLarge;
    case 'YOUTUBE_NO_TRANSCRIPT':
      return l10n.errorYoutubeNoTranscript;
    case 'YOUTUBE_UNAVAILABLE':
      return l10n.errorYoutubeUnavailable;
    case 'YOUTUBE_TOO_LONG':
      return l10n.errorYoutubeTooLong;
    case 'CONTENT_TOO_SHORT':
      return l10n.errorContentTooShort;
    case 'AI_TIMEOUT':
      return l10n.errorAiTimeout;
    case 'AI_FAILED':
    case 'AI_NOT_CONFIGURED':
    case 'SOURCE_FETCH_FAILED':
    case 'INTERNAL':
      return l10n.errorAiFailed;
    case 'NOT_PREMIUM':
      return l10n.errorNotPremium;
    case 'QUOTA_EXCEEDED':
      return l10n.errorQuotaExceeded;
    case 'JOB_ALREADY_RUNNING':
      return l10n.errorJobRunning;
    default:
      return l10n.errorGeneric;
  }
}
