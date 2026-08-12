part of '../../learning_import.dart';

/// "Creating your lesson" — the wait, given a screen of its own.
///
/// Minimising is the whole point of the button in the corner: generation takes
/// minutes, and a screen the user is not allowed to leave turns a background job
/// into a hostage situation. Leaving does not cancel anything — the job runs
/// server-side and [ImportDonePopupHost] surfaces the result wherever the reader
/// happens to be.
class ImportGeneratingPage extends StatefulWidget {
  const ImportGeneratingPage({super.key});

  @override
  State<ImportGeneratingPage> createState() => _ImportGeneratingPageState();
}

class _ImportGeneratingPageState extends State<ImportGeneratingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return BlocConsumer<LearningImportCubit, LearningImportState>(
      listenWhen: (previous, current) =>
          previous.isFinished != current.isFinished ||
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        // Finished while the user was still watching: take them straight in.
        // The done popup only exists for the case where they walked away.
        final lessonId = state.finishedLessonId;
        if (lessonId != null && lessonId.isNotEmpty && context.mounted) {
          LessonReaderRoute(lessonId).pushReplacement(context);
        }
      },
      builder: (context, state) {
        final percent = state.job?.percent ?? 0;

        return Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 20.w,
                  top: 10.h,
                  child: _MinimizeButton(
                    onTap: () {
                      AppHaptic.select();
                      // Pop back to wherever the import was started from. The
                      // job keeps running — see the class doc.
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 34.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FloatingIllustration(animation: _float),
                        22.verticalSpace,
                        AppText(
                          l10n.generatingTitle,
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold24.copyWith(
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        10.verticalSpace,
                        AppText(
                          state.errorCode != null
                              ? learningImportErrorText(context, state.errorCode)
                              : _stageLabel(context, state),
                          textAlign: TextAlign.center,
                          style: AppStyle.text14.copyWith(
                            fontSize: 14.5.sp,
                            height: 1.5,
                            color: state.errorCode != null
                                ? AppCustomColor.errorRed
                                : AppCustomColor.textTertiary,
                          ),
                          maxLines: 3,
                        ),
                        30.verticalSpace,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 10.h,
                            backgroundColor: const Color(0xFFEDF0F5),
                            valueColor: const AlwaysStoppedAnimation(
                              AppCustomColor.brandPrimary,
                            ),
                          ),
                        ),
                        12.verticalSpace,
                        AppText(
                          l10n.generatingPercent(percent: percent),
                          style: AppStyle.textBold12.copyWith(
                            fontSize: 13.sp,
                            color: AppCustomColor.brandPrimary,
                          ),
                        ),
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

  /// What the server says it is doing right now, falling back to the generic
  /// "you can leave" line before the first heartbeat lands.
  String _stageLabel(BuildContext context, LearningImportState state) {
    final l10n = context.l10n.learningImport;

    return switch (state.job?.stage) {
      ImportJobStageEntity.fetching => l10n.stageFetching,
      ImportJobStageEntity.generating => l10n.stageGenerating,
      ImportJobStageEntity.validating => l10n.stageValidating,
      ImportJobStageEntity.saving => l10n.stageSaving,
      ImportJobStageEntity.dubbing => l10n.stageDubbing,
      // No stage yet (or one this build does not know): say the thing that is
      // true regardless — they can walk away.
      _ => l10n.workingLeaveHint,
    };
  }
}

class _MinimizeButton extends StatelessWidget {
  const _MinimizeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.learningImport.minimize,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36.w,
          height: 36.w,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F4F8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22.w,
            color: AppCustomColor.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The illustration, drifting, over a breathing glow.
///
/// Both motions run off ONE controller at different phases rather than two: a
/// second ticker for a decoration is a second thing to leak, and the design's
/// two loops are close enough in period that sharing reads the same.
class _FloatingIllustration extends StatelessWidget {
  const _FloatingIllustration({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210.h,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(animation.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.55 + 0.35 * t,
                child: Transform.scale(
                  scale: 0.94 + 0.12 * t,
                  child: Container(
                    width: 190.w,
                    height: 190.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFFDFDCFB), Color(0x00EEEDFB)],
                        stops: [0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -12 * t),
                child: child,
              ),
            ],
          );
        },
        child: SvgPicture.asset(
          AppAsset.svg.app.importIllus,
          width: 300.w,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
