part of '../../learning_import.dart';

/// Local latch: the id of the last finished import the reader was told about.
///
/// Persisted rather than kept in memory because the whole point is to survive
/// the app being closed — someone who starts an import, kills MeUp and comes
/// back ten minutes later must still be told, and must be told only once.
const String _kLastNotifiedImportJobKey = 'learning_import.last_notified_job';

/// Tells the reader their lesson is ready, wherever they are in the app.
///
/// Lives on the shell beside [StreakPopupHost] and [GiftPopupHost], for the
/// reason those two spell out: the shell survives tab switches, so the check
/// still runs for someone who wandered into Explore or Profile while their
/// import was being generated.
///
/// It watches RESUME as well as mount, and that is the part that makes leaving
/// the app work at all. iOS suspends a backgrounded process, so
/// [LearningImportCubit]'s polling timer simply stops — without a resume check
/// the reader would come back to a progress screen frozen at whatever percent it
/// had reached, forever.
class ImportDonePopupHost extends StatefulWidget {
  const ImportDonePopupHost({super.key, required this.child});

  final Widget child;

  @override
  State<ImportDonePopupHost> createState() => _ImportDonePopupHostState();
}

class _ImportDonePopupHostState extends State<ImportDonePopupHost>
    with WidgetsBindingObserver {
  /// Guards a second pass while the first is still awaiting storage or the
  /// popup — iOS can deliver `resumed` more than once around a system prompt,
  /// and both passes would otherwise race for the same latch.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Refresh first, then look: the cubit's timer died when the app went away,
    // so without this the job it holds is as stale as the moment we left.
    unawaited(
      AppDI.injector
          .get<LearningImportCubit>()
          .refreshActiveJob()
          .then((_) => _check()),
    );
  }

  Future<void> _check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final job = AppDI.injector.get<LearningImportCubit>().state.job;
      if (job == null || job.isRunning) return;

      final store = AppDI.injector.get<ILocalStoreService>();
      final lastNotified = await store.getString(
        key: _kLastNotifiedImportJobKey,
      );
      if (lastNotified == job.id) return;
      if (!mounted) return;

      // Spend the ticket BEFORE showing. A popup that throws on the way up
      // would otherwise reappear on every resume for the rest of the install.
      await store.setString(key: _kLastNotifiedImportJobKey, value: job.id);
      if (!mounted) return;

      await _showPopup(job);
    } finally {
      _busy = false;
    }
  }

  Future<void> _showPopup(LearningImportJobEntity job) {
    final l10n = context.l10n.learningImport;
    final succeeded = job.isDone && (job.userLessonId?.isNotEmpty ?? false);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppCustomColor.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: AppText(
          succeeded ? l10n.donePopupTitle : l10n.failedPopupTitle,
          style: AppStyle.textBold16,
        ),
        content: AppText(
          succeeded
              ? l10n.donePopupBody(name: job.sourceLabel)
              : (job.status == ImportJobStatusEntity.interrupted
                    ? l10n.errorInterrupted
                    : learningImportErrorText(dialogContext, job.errorCode)),
          maxLines: 4,
          style: AppStyle.text14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: AppText(l10n.donePopupLater, style: AppStyle.text14),
          ),
          if (succeeded)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                LessonReaderRoute(job.userLessonId!).push(context);
              },
              child: AppText(
                l10n.donePopupRead,
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.brandPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
