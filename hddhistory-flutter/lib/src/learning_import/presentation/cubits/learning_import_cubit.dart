part of '../../learning_import.dart';

/// How often the waiting screen asks the server how it is going.
///
/// Three seconds is a compromise: the job takes minutes, so this is far more
/// often than the answer changes, but anything slower makes the stage label lag
/// visibly behind reality and the screen feel stuck.
const _kPollInterval = Duration(seconds: 3);

/// The run this device is watching, remembered across launches.
///
/// Generation takes minutes and the reader is explicitly invited to walk away —
/// including by killing the app. The job keeps running on the server either way,
/// but without its id on disk the next launch starts with `state.job == null`
/// and the app goes silent about it: no toast, no progress row on the shelf, and
/// [ImportDonePopupHost] never says it finished — the very thing that host's own
/// doc comment promises ("kills HDDhistory and comes back ten minutes later must still
/// be told"). Cleared the moment a poll sees the job reach a terminal state.
const String _kActiveImportJobKey = 'learning_import.active_job';

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

  /// What the progress bars draw. Owned here, not by either bar, because the
  /// reader moves between them mid-job — see [ImportProgressCreep].
  final ImportProgressCreep progress = ImportProgressCreep();

  /// Resolved on use rather than injected: this cubit's constructor is generated
  /// into the DI graph, and the store is a lazy singleton anyway (same pattern as
  /// [UserCubit]).
  ILocalStoreService get _store => AppDI.injector.get<ILocalStoreService>();

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
    progress.restart();
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
          // A new run starts from empty, whatever the last one left behind.
          progress.restart();
          _feedProgress(job);
          emit(state.copyWith(status: LearningImportStatus.success, job: job, toastDismissed: false));
          // Written before the first poll, not after: the app can be killed
          // during the very first seconds of a run too.
          unawaited(_store.setString(key: _kActiveImportJobKey, value: job.id));
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
        _feedProgress(job);
        emit(state.copyWith(job: job, errorCode: job.errorCode));

        if (!job.isRunning) {
          _pollTimer?.cancel();
          _pollTimer = null;
          // Terminal: there is nothing left to come back to, so stop carrying
          // the id into the next launch.
          unawaited(_store.remove(key: _kActiveImportJobKey));
        }
      },
    );
  }

  /// Ask the server where the watched job stands, right now.
  ///
  /// Called by [ImportDonePopupHost] on mount and on every app resume. Two gaps,
  /// one answer: the polling timer does not survive the app being suspended, so
  /// on the way back the job this cubit holds is as stale as the moment the
  /// reader left — and it does not survive the app being KILLED at all, in which
  /// case there is no job in memory either and the id comes off disk
  /// ([_kActiveImportJobKey]).
  Future<void> refreshActiveJob() async {
    final watched = state.job;
    // Already finished and already dealt with — re-asking would only resurrect
    // an announcement the reader has had.
    if (watched != null && !watched.isRunning) return;

    final jobId = watched?.id ?? await _store.getString(key: _kActiveImportJobKey);
    if (jobId.isEmpty) return;

    final wasRestoredFromDisk = watched == null;
    await _poll(jobId);

    if (state.job?.isRunning ?? false) {
      _startPolling(jobId);
      return;
    }

    // A run from a previous launch that had already finished. The done popup is
    // what tells them, so don't ALSO raise the shell's toast for the same event
    // one dialog later.
    if (wasRestoredFromDisk && state.job != null) {
      emit(state.copyWith(toastDismissed: true));
    }
  }

  /// Called when the user comes back to a job started earlier — the flow they
  /// get by leaving the waiting screen and tapping the in-progress card.
  /// Hide the shell's progress toast for the rest of this run. Cleared when a
  /// new run starts (see [_create]) so the next import announces itself.
  void dismissToast() => emit(state.copyWith(toastDismissed: true));

  void watchJob(LearningImportJobEntity job) {
    // Coming back to a job already in flight: the bar has no history to
    // continue from, so it fills into the phase the job is already in rather
    // than replaying the phases it missed.
    progress.restart();
    _feedProgress(job);
    emit(state.copyWith(job: job, status: LearningImportStatus.success));
    if (job.isRunning) _startPolling(job.id);
  }

  /// Hand the bars the one thing they need off a job: which phase it is in.
  void _feedProgress(LearningImportJobEntity job) => progress.onJob(
    serverPercent: job.isDone ? 100 : job.percent,
    isFailed: job.isFailed,
  );

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    progress.dispose();
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
    case 'YOUTUBE_TOO_SHORT':
      return l10n.errorYoutubeTooShort;
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
