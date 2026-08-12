part of '../../learning_import.dart';

/// Ceiling shown on the PDF drop zone. Display only — the API enforces the real
/// bound, and a number here that disagreed with it would be a promise we cannot
/// keep.
const int _kPdfLimitMb = 20;

/// "Make your own lesson" — a full screen, not a sheet.
///
/// The flow used to be a four-step bottom sheet (source → language → confirm →
/// working). The redesign collapses it into ONE screen: pick a source, give it
/// the material, press Generate. Two things went with the steps and both were
/// deliberate:
///
/// - **The language step is gone.** The lesson is written in whatever language
///   the app is in. It was a question asked before the user had done anything,
///   about a lesson that did not exist yet, and almost nobody wants a lesson in
///   a language they are not reading the app in.
/// - **The confirm step is gone.** Everything it summarised is on screen at the
///   moment you press the button.
class ImportLessonPage extends StatefulWidget {
  const ImportLessonPage({super.key});

  @override
  State<ImportLessonPage> createState() => _ImportLessonPageState();
}

enum _ImportSource { youtube, pdf }

class _ImportLessonPageState extends State<ImportLessonPage> {
  _ImportSource _source = _ImportSource.youtube;
  final TextEditingController _linkController = TextEditingController();
  File? _pickedFile;
  String _pickedMeta = '';
  bool _showLinkError = false;

  @override
  void initState() {
    super.initState();
    context.read<LearningImportCubit>().loadQuota();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool get _canGenerate => _source == _ImportSource.youtube
      ? _linkController.text.trim().isNotEmpty
      : _pickedFile != null;

  Future<void> _pickPdf() async {
    // Through the app's own helper rather than FilePicker directly: it asks for
    // storage permission first and reports a denied pick the same way every
    // other picker in the app does.
    final file = await FileService.pickFile();
    if (file == null || !mounted) return;

    final bytes = await file.length();
    if (!mounted) return;
    setState(() {
      _pickedFile = file;
      _pickedMeta = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    });
  }

  /// Straight to the paywall — the Create button's answer for a free reader
  /// whose one ticket is spent (the popups below are the PILL's answer).
  void _openUpgrade() {
    AppHaptic.select();
    AppDI.injector.get<IapCubit>().setPaywallEntryPoint(
      PaywallEntryPoint.learningImport,
    );
    unawaited(const PaywallRoute().push(context));
  }

  /// The ticket pill, tapped: the popup that matches the reader's tier (design
  /// `4 · Explore` — "popup số ticket & reset" / "popup số ticket").
  ///
  /// Supersedes the straight-to-paywall pill (product call, 2026-08-12, then
  /// re-decided the same day with the design): both tiers get the count said
  /// out loud — including "0 tickets left" — a free reader gets the Premium
  /// pitch under it, a subscriber gets the reset countdown and nothing sold.
  void _showTicketPopup() {
    AppHaptic.select();
    final quota = context.read<LearningImportCubit>().state.quota;
    if (!quota.isKnown) return;
    if (quota.isPremium) {
      unawaited(showImportTicketInfoPopup(context, quota: quota));
    } else {
      unawaited(showImportTicketUpsellPopup(context, quota: quota));
    }
  }

  /// A subscriber who has spent the week's allowance. Nothing to sell and nothing
  /// to explain — just the day it comes back, where they pressed.
  ///
  /// The refill day is NAMED, not dated ('EEEE'): the window is a calendar week,
  /// so the answer is always a weekday and "on Monday" is what a reader repeats
  /// back.
  void _tellPremiumToWait(ImportQuotaEntity quota) {
    final resetsAt = quota.resetsAt;
    DMessage.showSnackBar(
      message: l10n.learningImport.ticketNoteBalance(
        count: 0,
        limit: quota.limit,
        date: resetsAt == null ? '' : resetsAt.toLocal().parseString('EEEE'),
      ),
    );
  }

  Future<void> _generate() async {
    final cubit = context.read<LearningImportCubit>();
    final quota = cubit.state.quota;

    // Switched off. Nothing to buy and nothing to wait for, so neither ticket
    // popup fits — the note above the form already says it, and the button
    // simply does not fire.
    if (quota.isFeatureOff) return;

    // Spending a ticket the reader does not have is a request that comes back
    // rejected, so it is answered here instead — the paywall for a free reader
    // who has used their one import, the refill day for a subscriber mid-week.
    // Skipped when the allowance was never read (see `isKnown`): there the
    // server stays the judge.
    if (quota.isKnown && !quota.canImport) {
      quota.isPremium ? _tellPremiumToWait(quota) : _openUpgrade();
      return;
    }

    // The lesson is written in the language the app is in — see the class doc
    // for why this is no longer asked.
    final locale = AppDI.injector.get<LocaleCubit>().state.languageCode;

    if (_source == _ImportSource.youtube) {
      final url = _linkController.text.trim();
      if (!_looksLikeYoutube(url)) {
        setState(() => _showLinkError = true);
        return;
      }
      await cubit.startYoutubeImport(url: url, outputLocale: locale);
    } else {
      final file = _pickedFile;
      if (file == null) return;
      await cubit.startPdfImport(file: file, outputLocale: locale);
    }
  }

  /// A cheap shape check so an obvious typo is caught before a request. The
  /// server parses the id properly and is the one that decides.
  static bool _looksLikeYoutube(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com/') || lower.contains('youtu.be/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return BlocConsumer<LearningImportCubit, LearningImportState>(
      listenWhen: (previous, current) => previous.job?.id != current.job?.id,
      listener: (context, state) {
        // The run has started: this screen's job is done and the generating
        // screen takes over. Replaces rather than stacks — coming "back" to a
        // form whose submission is already in flight makes no sense.
        if (state.job != null && context.mounted) {
          const ImportGeneratingRoute().pushReplacement(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(quota: state.quota, onPillTap: _showTicketPopup),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 40.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          l10n.makeTitle,
                          style: AppStyle.textBold24.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppCustomColor.textPrimary,
                          ),
                          maxLines: 3,
                        ),
                        10.verticalSpace,
                        AppText(
                          l10n.makeSubtitle,
                          style: AppStyle.text14.copyWith(
                            fontSize: 14.5.sp,
                            height: 1.5,
                            color: AppCustomColor.textTertiary,
                          ),
                          maxLines: 4,
                        ),
                        24.verticalSpace,
                        if (state.quota.isFeatureOff) ...[
                          _FeatureOffNote(note: state.quota.disabledNote),
                          18.verticalSpace,
                        ],
                        _SourcePicker(
                          selected: _source,
                          onSelect: (value) => setState(() {
                            _source = value;
                            _showLinkError = false;
                          }),
                        ),
                        22.verticalSpace,
                        if (_source == _ImportSource.youtube)
                          _LinkField(
                            controller: _linkController,
                            hasError: _showLinkError,
                            onChanged: () => setState(() => _showLinkError = false),
                          )
                        else if (_pickedFile == null)
                          _PdfDropZone(onTap: _pickPdf)
                        else
                          _PickedFileRow(
                            name: _pickedFile!.path.split('/').last,
                            meta: _pickedMeta,
                            onClear: () => setState(() => _pickedFile = null),
                          ),
                        if (_showLinkError) ...[
                          8.verticalSpace,
                          AppText(
                            l10n.youtubeInvalid,
                            style: AppStyle.text12.copyWith(color: AppCustomColor.errorRed),
                            maxLines: 2,
                          ),
                        ],
                        if (state.errorCode != null) ...[
                          8.verticalSpace,
                          AppText(
                            learningImportErrorText(context, state.errorCode),
                            style: AppStyle.text12.copyWith(color: AppCustomColor.errorRed),
                            maxLines: 3,
                          ),
                        ],
                        26.verticalSpace,
                        Center(
                          child: _GenerateButton(
                            enabled: _canGenerate &&
                                !state.isBusy &&
                                !state.quota.isFeatureOff,
                            busy: state.isBusy,
                            onTap: _generate,
                          ),
                        ),
                        26.verticalSpace,
                        const _HowItWorks(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Close button on the left, credits on the right.
class _Header extends StatelessWidget {
  const _Header({required this.quota, required this.onPillTap});

  final ImportQuotaEntity quota;
  final VoidCallback onPillTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.l10n.common.close,
            child: GestureDetector(
              onTap: () {
                AppHaptic.select();
                Navigator.of(context).maybePop();
              },
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.close_rounded,
                size: 26.w,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Hidden until the allowance is actually known — a pill reading "0"
          // because the request dropped is a lie about the reader's account.
          if (quota.isKnown) _CreditsPill(quota: quota, onTap: onPillTap),
        ],
      ),
    );
  }
}

/// Why the form will not run, in the admin's own words when there are any.
///
/// Amber rather than red: nothing is broken and nobody did anything wrong. The
/// server's note wins when it exists — it is the only place that can say WHY —
/// and the app's own line covers the case where the admin left it empty, in the
/// reader's language rather than the admin's.
class _FeatureOffNote extends StatelessWidget {
  const _FeatureOffNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF5E2B0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            size: 20.w,
            color: const Color(0xFFB77B08),
          ),
          11.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  l10n.featureOffTitle,
                  style: AppStyle.textBold14.copyWith(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF8A5D00),
                  ),
                  maxLines: 2,
                ),
                4.verticalSpace,
                AppText(
                  note.trim().isNotEmpty ? note.trim() : l10n.featureOffBody,
                  style: AppStyle.text12.copyWith(
                    fontSize: 13.sp,
                    height: 1.45,
                    color: const Color(0xFF8A5D00),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The allowance as a sentence, under the subtitle.
///
/// The pill above it carries the number; this carries the meaning — how many are
/// left and when they refill, or, for a reader without Premium, what the feature
/// costs. It sits ABOVE the source picker deliberately: the design puts the
/// constraint before the work, so nobody picks a file, pastes a link and only
/// then learns they cannot spend anything.
/// The balance, tappable for everyone — the popup behind it differs by tier
/// (see `_showTicketPopup`), the affordance does not. The `+` badge stays a
/// non-subscriber mark: it is the "there is more to have" sign, and a
/// subscriber's popup sells nothing.
class _CreditsPill extends StatelessWidget {
  const _CreditsPill({required this.quota, required this.onTap});

  final ImportQuotaEntity quota;
  final VoidCallback onTap;

  bool get _canUpgrade => !quota.isPremium;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.learningImport.quotaRemaining(
        remaining: quota.remaining,
        limit: quota.limit,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.fromLTRB(13.w, 6.h, _canUpgrade ? 6.w : 13.w, 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDFB),
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 17.w,
                color: AppCustomColor.brandPrimary,
              ),
              8.horizontalSpace,
              AppText(
                '${quota.remaining}',
                style: AppStyle.textBold16.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppCustomColor.brandPrimary,
                ),
              ),
              if (_canUpgrade) ...[
                8.horizontalSpace,
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.add_rounded, size: 14.w, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.selected, required this.onSelect});

  final _ImportSource selected;
  final ValueChanged<_ImportSource> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Row(
      children: [
        Expanded(
          child: _SourceCard(
            label: l10n.sourceYoutube,
            tint: const Color(0xFFFDE7E7),
            icon: Icon(Icons.play_arrow_rounded, size: 24.w, color: const Color(0xFFE23B3B)),
            isSelected: selected == _ImportSource.youtube,
            onTap: () => onSelect(_ImportSource.youtube),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: _SourceCard(
            label: l10n.sourcePdf,
            tint: const Color(0xFFE8EEFD),
            icon: Icon(Icons.description_outlined, size: 22.w, color: const Color(0xFF3567CE)),
            isSelected: selected == _ImportSource.pdf,
            onTap: () => onSelect(_ImportSource.pdf),
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.label,
    required this.tint,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color tint;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              12.verticalSpace,
              AppText(
                label,
                style: AppStyle.textBold16.copyWith(fontSize: 15.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(
          color: hasError ? AppCustomColor.errorRed : const Color(0xFFE4E8EF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 19.w, color: AppCustomColor.textTertiary),
          10.horizontalSpace,
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              style: AppStyle.text14.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: context.l10n.learningImport.pasteLinkHint,
                hintStyle: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfDropZone extends StatelessWidget {
  const _PdfDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Semantics(
      button: true,
      label: l10n.choosePdf,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: const Color(0xFFC9CFDB),
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
            radius: Radius.circular(20.r),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 30.w,
                  color: AppCustomColor.textTertiary,
                ),
                8.verticalSpace,
                AppText(l10n.choosePdf, style: AppStyle.textBold14.copyWith(fontSize: 14.5.sp)),
                4.verticalSpace,
                AppText(
                  l10n.choosePdfHint(size: _kPdfLimitMb),
                  style: AppStyle.text12.copyWith(
                    fontSize: 12.5.sp,
                    color: AppCustomColor.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({
    required this.name,
    required this.meta,
    required this.onClear,
  });

  final String name;
  final String meta;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE4E8EF), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFD),
              borderRadius: BorderRadius.circular(11.r),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.description_outlined, size: 18.w, color: const Color(0xFF3567CE)),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  name,
                  style: AppStyle.textBold14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppText(
                  meta,
                  style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          Semantics(
            button: true,
            label: context.l10n.learningImport.cancel,
            child: GestureDetector(
              onTap: () {
                AppHaptic.select();
                onClear();
              },
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: AppCustomColor.neutral300,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 14.w, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: context.l10n.learningImport.generateCta,
      child: GestureDetector(
        onTap: enabled
            ? () {
                AppHaptic.select();
                onTap();
              }
            : null,
        child: Container(
          height: 52.h,
          padding: EdgeInsets.symmetric(horizontal: 26.w),
          decoration: BoxDecoration(
            // Disabled reads as a flat neutral rather than a dimmed brand: a
            // faded primary still looks pressable, and this button is the one
            // that spends a credit.
            color: enabled ? AppCustomColor.brandPrimary : AppCustomColor.neutral100,
            borderRadius: BorderRadius.circular(99.r),
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : AppText(
                  context.l10n.learningImport.generateCta,
                  style: AppStyle.textBold16.copyWith(
                    fontSize: 15.5.sp,
                    color: enabled ? Colors.white : AppCustomColor.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    final steps = [l10n.howStep1, l10n.howStep2, l10n.howStep3];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppCustomColor.borderSecondary),
        20.verticalSpace,
        AppText(l10n.howItWorks, style: AppStyle.textBold16.copyWith(fontSize: 15.sp)),
        14.verticalSpace,
        for (final (index, step) in steps.indexed) ...[
          if (index > 0) 12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppText(
                  '${index + 1}',
                  style: AppStyle.textBold12.copyWith(
                    fontSize: 12.5.sp,
                    color: AppCustomColor.brandPrimary,
                  ),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  step,
                  style: AppStyle.text14.copyWith(
                    fontSize: 13.5.sp,
                    height: 1.4,
                    color: AppCustomColor.textSecondary,
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
