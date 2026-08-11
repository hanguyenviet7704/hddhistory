part of '../../learning_import.dart';

/// Opens the three-step import flow and resolves when it closes.
Future<void> showImportSourceSheet(BuildContext context) {
  context.read<LearningImportCubit>().loadQuota();

  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: AppCustomColor.backgroundWhite,
    barrierColor: AppCustomColor.bottomSheetScrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<LearningImportCubit>(),
      child: const _ImportSourceSheet(),
    ),
  );
}

enum _ImportStep { source, language, confirm, working }

/// Source → language → confirm, then the waiting screen.
///
/// One sheet rather than a pushed flow so backing out at any step returns the
/// user exactly where they started, and so the waiting state can hand over to
/// the finished lesson without a stack of dead routes behind it.
class _ImportSourceSheet extends StatefulWidget {
  const _ImportSourceSheet();

  @override
  State<_ImportSourceSheet> createState() => _ImportSourceSheetState();
}

class _ImportSourceSheetState extends State<_ImportSourceSheet> {
  final TextEditingController _urlController = TextEditingController();

  _ImportStep _step = _ImportStep.source;
  File? _pickedFile;
  String? _youtubeUrl;
  late String _locale = LocaleSettings.currentLocale.languageCode;
  String? _inlineError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final file = await FileService.pickFile();
    if (file == null) return;

    setState(() {
      _pickedFile = file;
      _youtubeUrl = null;
      _inlineError = null;
      _step = _ImportStep.language;
    });
  }

  void _submitUrl() {
    final url = _urlController.text.trim();

    // Validated here so a typo is caught before anything is spent — the server
    // would reject it too, but a minute later and after a round trip.
    if (!_looksLikeYoutubeUrl(url)) {
      setState(() => _inlineError = context.l10n.learningImport.youtubeInvalid);
      return;
    }

    setState(() {
      _youtubeUrl = url;
      _pickedFile = null;
      _inlineError = null;
      _step = _ImportStep.language;
    });
  }

  void _start() {
    final cubit = context.read<LearningImportCubit>();
    setState(() => _step = _ImportStep.working);

    if (_pickedFile != null) {
      cubit.startPdfImport(file: _pickedFile!, outputLocale: _locale);
    } else if (_youtubeUrl != null) {
      cubit.startYoutubeImport(url: _youtubeUrl!, outputLocale: _locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LearningImportCubit, LearningImportState>(
      listenWhen: (previous, current) =>
          previous.finishedLessonId != current.finishedLessonId,
      listener: (context, state) {
        final lessonId = state.finishedLessonId;
        if (lessonId == null || lessonId.isEmpty) return;

        // Close and let `ImportDonePopupHost` do the handover. It does not
        // matter whether the reader stayed on this sheet or wandered off — one
        // path announces a finished import, so there is no second path to rot.
        Navigator.of(context).pop();
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.borderDefault,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              20.verticalSpace,
              switch (_step) {
                _ImportStep.source => _buildSourceStep(),
                _ImportStep.language => _buildLanguageStep(),
                _ImportStep.confirm => _buildConfirmStep(),
                _ImportStep.working => const _WorkingView(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceStep() {
    final l10n = context.l10n.learningImport;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(l10n.sourceStepTitle, style: AppStyle.textBold16),
        16.verticalSpace,
        _SourceTile(
          icon: Icons.picture_as_pdf_outlined,
          title: l10n.sourcePdfTitle,
          body: l10n.sourcePdfBody,
          onTap: _pickPdf,
        ),
        12.verticalSpace,
        AppText(l10n.sourceYoutubeTitle, style: AppStyle.textBold16),
        4.verticalSpace,
        AppText(
          l10n.sourceYoutubeBody,
          style: AppStyle.text12.copyWith(color: AppCustomColor.textSecondary),
        ),
        8.verticalSpace,
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: l10n.youtubeHint,
            errorText: _inlineError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          onSubmitted: (_) => _submitUrl(),
        ),
        16.verticalSpace,
        DButton(
          text: context.l10n.common.kContinue,
          backgroundColor: AppCustomColor.brandPrimary,
          size: Size(double.infinity, 52.h),
          style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
          onPressed: _submitUrl,
        ),
      ],
    );
  }

  Widget _buildLanguageStep() {
    final l10n = context.l10n.learningImport;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(l10n.languageStepTitle, style: AppStyle.textBold16),
        6.verticalSpace,
        AppText(
          l10n.languageStepBody,
          maxLines: 3,
          style: AppStyle.text12.copyWith(color: AppCustomColor.textSecondary),
        ),
        16.verticalSpace,
        // RadioGroup rather than per-tile groupValue/onChanged: those were
        // deprecated on the Flutter channel this project is on, and the ancestor
        // form is the replacement.
        RadioGroup<String>(
          groupValue: _locale,
          onChanged: (value) => setState(() => _locale = value ?? _locale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in _kOutputLocales)
                RadioListTile<String>(
                  value: option.code,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppCustomColor.brandPrimary,
                  title: AppText(option.label, style: AppStyle.text14),
                ),
            ],
          ),
        ),
        16.verticalSpace,
        DButton(
          text: context.l10n.common.kContinue,
          backgroundColor: AppCustomColor.brandPrimary,
          size: Size(double.infinity, 52.h),
          style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
          onPressed: () => setState(() => _step = _ImportStep.confirm),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final l10n = context.l10n.learningImport;
    final sourceLabel =
        _pickedFile?.path.split('/').last ?? _youtubeUrl ?? '';

    return BlocBuilder<LearningImportCubit, LearningImportState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(l10n.confirmStepTitle, style: AppStyle.textBold16),
            16.verticalSpace,
            _ConfirmRow(label: l10n.confirmSource, value: sourceLabel),
            8.verticalSpace,
            _ConfirmRow(
              label: l10n.confirmLanguage,
              value: _kOutputLocales
                  .firstWhere((option) => option.code == _locale)
                  .label,
            ),
            12.verticalSpace,
            // Credits shown before they commit, not after — being told "hết
            // lượt" at the moment you press Create is the worst place to learn it.
            AppText(
              l10n.quotaRemaining(
                remaining: state.quota.remaining,
                limit: state.quota.limit,
              ),
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textSecondary,
              ),
            ),
            20.verticalSpace,
            DButton(
              text: l10n.confirmStart,
              backgroundColor: AppCustomColor.brandPrimary,
              size: Size(double.infinity, 52.h),
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.textWhite,
              ),
              onPressed: _start,
            ),
          ],
        );
      },
    );
  }
}

/// Progress while the job runs, and the failure state when it does not.
class _WorkingView extends StatelessWidget {
  const _WorkingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return BlocBuilder<LearningImportCubit, LearningImportState>(
      builder: (context, state) {
        final job = state.job;

        if (job?.isFailed ?? false) {
          final isInterrupted =
              job!.status == ImportJobStatusEntity.interrupted;

          return _FailureView(
            message: isInterrupted
                ? l10n.errorInterrupted
                : learningImportErrorText(context, state.errorCode),
          );
        }

        if (state.status == LearningImportStatus.failure) {
          return _FailureView(
            message: state.errorMessage ?? l10n.errorGeneric,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            24.verticalSpace,
            const CircularProgressIndicator(),
            20.verticalSpace,
            AppText(l10n.workingTitle, style: AppStyle.textBold16),
            8.verticalSpace,
            // The step being worked on, not a bar that moves for its own sake.
            AppText(
              state.uploading
                  ? l10n.uploading
                  : _stageLabel(context, state.job?.stage),
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
              ),
            ),
            16.verticalSpace,
            AppText(
              l10n.workingLeaveHint,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textSecondary,
              ),
            ),
            24.verticalSpace,
          ],
        );
      },
    );
  }

  String _stageLabel(BuildContext context, ImportJobStageEntity? stage) {
    final l10n = context.l10n.learningImport;

    return switch (stage) {
      ImportJobStageEntity.generating => l10n.stageGenerating,
      ImportJobStageEntity.validating => l10n.stageValidating,
      ImportJobStageEntity.saving => l10n.stageSaving,
      _ => l10n.stageFetching,
    };
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        16.verticalSpace,
        Icon(
          Icons.error_outline_rounded,
          size: 40.w,
          color: AppCustomColor.backgroundError,
        ),
        12.verticalSpace,
        AppText(
          message,
          textAlign: TextAlign.center,
          maxLines: 4,
          style: AppStyle.text14,
        ),
        20.verticalSpace,
        DButton(
          text: context.l10n.learningImport.retry,
          backgroundColor: AppCustomColor.brandPrimary,
          size: Size(double.infinity, 52.h),
          style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
          onPressed: () {
            context.read<LearningImportCubit>().reset();
            Navigator.of(context).pop();
          },
        ),
        8.verticalSpace,
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        key: const Key('import-source-pdf'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24.w, color: AppCustomColor.brandPrimary),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(title, style: AppStyle.textBold16),
                    2.verticalSpace,
                    AppText(
                      body,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22.w,
                color: AppCustomColor.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: AppText(
            label,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: AppText(value, maxLines: 2, style: AppStyle.text14),
        ),
      ],
    );
  }
}

/// Output languages, matching the five the app ships and the API accepts.
class _OutputLocale {
  final String code;
  final String label;

  const _OutputLocale(this.code, this.label);
}

const _kOutputLocales = <_OutputLocale>[
  _OutputLocale('vi', 'Tiếng Việt'),
  _OutputLocale('en', 'English'),
  _OutputLocale('zh', '中文'),
  _OutputLocale('ja', '日本語'),
  _OutputLocale('ko', '한국어'),
];

bool _looksLikeYoutubeUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasAuthority) return false;

  final host = uri.host.replaceFirst(RegExp(r'^(www\.|m\.)'), '');
  if (host == 'youtu.be') return uri.pathSegments.isNotEmpty;
  if (host != 'youtube.com') return false;

  return (uri.queryParameters['v']?.isNotEmpty ?? false) ||
      uri.pathSegments.length >= 2;
}
