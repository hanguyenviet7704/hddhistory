part of '../../lesson.dart';

class NoCorrectAnswerDocumentPage extends StatefulWidget {
  final String groupId;

  const NoCorrectAnswerDocumentPage({
    super.key,
    required this.groupId,
  });

  @override
  State<NoCorrectAnswerDocumentPage> createState() => _NoCorrectAnswerDocumentPageState();
}

class _NoCorrectAnswerDocumentPageState extends State<NoCorrectAnswerDocumentPage> {
  NoCorrectAnswerDocumentGroupResolved? _resolvedGroup;
  // Guards against a second pop: a fast double-tap on Continue (or tapping
  // while the route is still transitioning in) otherwise calls context.pop()
  // on a non-idle route, throwing the NavigatorState.pop assertion and leaving
  // the course-branch stack corrupted — which downstream stops
  // PageCubit.currentRouteName from settling and hides the shell's bottom nav.
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();

    final currentQuestion = context.read<ChoiceCubit>().state.question;
    _resolvedGroup = resolveNoCorrectAnswerDocumentGroupById(
      question: currentQuestion,
      groupId: widget.groupId,
    );

    if (_resolvedGroup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dismiss(false);
      });
    }
  }

  void _dismiss(bool result) {
    if (_isPopping || !mounted) return;
    _isPopping = true;
    // Finishing a reading document (real Continue tap) is a completion beat, not
    // just a page turn — a firm confirmation. The silent auto-dismiss (missing
    // group, result == false) stays haptic-free.
    if (result) AppHaptic.success();
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGroup = _resolvedGroup;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: resolvedGroup == null
          ? const SizedBox.shrink()
          : _NoCorrectAnswerDocumentPopup(
              documents: resolvedGroup.documents,
              onContinue: () => _dismiss(true),
            ),
    );
  }
}

class _NoCorrectAnswerDocumentPopup extends StatelessWidget {
  final List<ContentDocumentEntity> documents;
  final VoidCallback onContinue;

  const _NoCorrectAnswerDocumentPopup({
    required this.documents,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: ColoredBox(
          color: AppCustomColor.scrimOverlay,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 335.w),
                        child: _NoCorrectAnswerDocumentCard(documents: documents),
                      ),
                    ),
                  ),
                  36.verticalSpace,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 335.w),
                    child: _NoCorrectAnswerDocumentContinueButton(
                      onPressed: onContinue,
                      text: context.l10n.common.kContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoCorrectAnswerDocumentContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const _NoCorrectAnswerDocumentContinueButton({
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary,
          borderRadius: BorderRadius.circular(1000.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.textPrimary.withValues(alpha: 0.12),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(1000.r),
            child: Center(
              child: AppText(
                text,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.textWhite,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoCorrectAnswerDocumentCard extends StatelessWidget {
  final List<ContentDocumentEntity> documents;

  const _NoCorrectAnswerDocumentCard({
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4.r,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NoCorrectAnswerDocumentHeader(),
              12.verticalSpace,
              if (documents.isNotEmpty)
                DocumentWidget(
                  documents: documents,
                  asCard: false,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCorrectAnswerDocumentHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          AppAsset.svg.app.icTennisRacket,
          width: 20.w,
          height: 20.w,
        ),
        6.horizontalSpace,
        AppText(
          context.l10n.exercise.exerciseExplanationTitle,
          style: AppStyle.text14.copyWith(
            color: const Color(0xFF175CD3),
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
      ],
    );
  }
}
