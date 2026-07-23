part of '../../habit.dart';

/// Re-anchor screen (Figma 11233:40564): before a course's first lesson, the
/// user picks one BTV-authored reason "why this matters to them" (single
/// choice) to build motivation, then "Start learning" proceeds into the lesson.
/// Picking is mandatory (back-out is blocked, first reason pre-selected), so it
/// always pops the chosen [ReanchorReasonEntity] — never null in the flow.
class ReanchorPage extends StatefulWidget {
  final List<ReanchorReasonEntity> reasons;

  const ReanchorPage({super.key, required this.reasons});

  static Future<ReanchorReasonEntity?> push(BuildContext context, {required List<ReanchorReasonEntity> reasons}) {
    // No slide transition: this is a "before you start" gate, not a secondary
    // page — it should cover the roadmap the instant it's pushed, not animate
    // in from the right (which reads as "roadmap first, then a new screen").
    return Navigator.of(context).push<ReanchorReasonEntity>(
      PageRouteBuilder<ReanchorReasonEntity>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => ReanchorPage(reasons: reasons),
      ),
    );
  }

  @override
  State<ReanchorPage> createState() => _ReanchorPageState();
}

class _ReanchorPageState extends State<ReanchorPage> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Figma shows the first reason pre-selected so the CTA is immediately live.
    if (widget.reasons.isNotEmpty) _selectedId = widget.reasons.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HabitTracking.reanchorScrView(courseId: widget.reasons.isNotEmpty ? widget.reasons.first.courseId : '');
    });
  }

  /// One selectable reason (Figma 11233:40564): a white outlined row — the
  /// selected one gets a brand border, no fill and no check mark.
  Widget _buildReasonOption(ReanchorReasonEntity r) {
    final selected = _selectedId == r.id;
    return Semantics(
      button: true,
      selected: selected,
      label: r.reason.text,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          AppHaptic.select();
          setState(() => _selectedId = r.id);
        },
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
              width: 2,
            ),
          ),
          child: AppText(
            r.reason.text,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              height: 1.75,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-anchor is a mandatory step in the flow — picking a reason is required.
    // Block the iOS swipe-back / Android back so the only way forward is the
    // "Start learning" CTA, which always pops the (pre-)selected reason. This
    // guarantees a reason is captured and the adopt "PROBLEM" headline is
    // always the user's re-anchor pick, never the raw course title.
    return PopScope(
      canPop: false,
      child: Scaffold(
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.brandPrimary50),
        body: ThemedBackground(
          child: SafePage(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  AppText(
                    context.l10n.habit.adoptHeaderLabel,
                    textAlign: TextAlign.center,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.streakActive,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  8.verticalSpace,
                  AppText(
                    context.l10n.habit.reanchorTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.text24.copyWith(fontWeight: FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                  ),
                  const Spacer(flex: 3),
                  // Card floats near the bottom (Figma), wrapping its content.
                  ThemedGlassCard(
                    padding: EdgeInsets.all(16.w),
                    radius: 20,
                    shadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 4)],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          context.l10n.habit.reanchorPickLabel,
                          style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary, fontWeight: FontWeight.w500),
                        ),
                        12.verticalSpace,
                        ...widget.reasons.map(_buildReasonOption),
                      ],
                    ),
                  ),
                  16.verticalSpace,
                  DButton(
                    text: context.l10n.habit.reanchorStartButton,
                    backgroundColor: AppCustomColor.brandPrimary,
                    size: Size(double.infinity, 54.h),
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                    onPressed: _selectedId == null
                        ? null
                        : () {
                            final selected = widget.reasons.where((r) => r.id == _selectedId).firstOrNull;
                            if (selected != null) {
                              HabitTracking.reanchorSelect(
                                anchorId: selected.id,
                                anchorName: selected.reason.text,
                                courseId: selected.courseId,
                              );
                            }
                            Navigator.of(context).pop(selected);
                          },
                  ),
                  20.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
