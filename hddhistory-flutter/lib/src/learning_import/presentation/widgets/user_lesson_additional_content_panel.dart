part of '../../learning_import.dart';

/// "Bạn có muốn yêu cầu thêm nội dung không?" at the end of a generated lesson's
/// roadmap — the counterpart of the catalogue's own end-of-level panel.
///
/// Same question, same two tiles, same copy (it reads `courseroadmap`'s strings
/// rather than cloning them into this module's YAML, so the two screens cannot
/// drift apart), and the same product meaning: a WISH is recorded, nothing is
/// generated and no import ticket is spent.
///
/// The catalogue's widget could not be reused — it is private to the course
/// library, is keyed to a `CourseLevel` and draws a "Complete level N" label
/// above itself, none of which a generated lesson has.
///
/// Only offered once the lesson is read out (the caller gates on
/// `isCompleted`): asking for MORE of something half-read is a question the
/// reader has no basis to answer, and the signal it produces would be noise.
class UserLessonAdditionalContentPanel extends StatefulWidget {
  const UserLessonAdditionalContentPanel({super.key, required this.lesson});

  final UserLessonEntity lesson;

  @override
  State<UserLessonAdditionalContentPanel> createState() => _UserLessonAdditionalContentPanelState();
}

class _UserLessonAdditionalContentPanelState extends State<UserLessonAdditionalContentPanel> {
  /// "No, it's enough" — kept in the widget, not on the server.
  ///
  /// The endpoint records a wish; there is no field for its absence, and adding
  /// one to store "this reader is not interested" would be a second column
  /// nothing reads. So no dismisses the panel for this visit and it is offered
  /// again next time, which is also the honest behaviour: an answer that was
  /// never sent anywhere should not look permanent.
  bool _dismissed = false;

  bool _isSubmitting = false;

  Future<void> _requestMore() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await context.read<UserLessonCubit>().requestAdditionalContent();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final l10n = context.l10n.courseroadmap;
    final answered = widget.lesson.hasRequestedMoreContent;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        // Solid, not the catalogue's translucent brand tint: this panel can sit
        // over a custom study background, where a tinted card lets a photo bleed
        // through the question.
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            l10n.additionalContentRequestQuestion,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            maxLines: 3,
          ),
          8.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AdditionalContentTile(
                  label: l10n.additionalContentRequestNoChoice,
                  iconAsset: answered ? AppAsset.svg.app.icConfusedFaceDisable : AppAsset.svg.app.icConfusedFace,
                  enabled: !answered && !_isSubmitting,
                  onTap: () => setState(() => _dismissed = true),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _AdditionalContentTile(
                  label: l10n.additionalContentRequestYesChoice,
                  iconAsset: AppAsset.svg.app.icSmilingFaceWithHearts,
                  selected: answered,
                  enabled: !answered && !_isSubmitting,
                  onTap: () => unawaited(_requestMore()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two answers. Visual twin of the catalogue's tile.
class _AdditionalContentTile extends StatelessWidget {
  const _AdditionalContentTile({
    required this.label,
    required this.iconAsset,
    required this.enabled,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(8.r),
        border: selected ? Border.all(color: AppCustomColor.paywallPromoLabel, width: 2.w) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && onTap != null
              ? () {
                  AppHaptic.select();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 74.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(iconAsset, width: 30.w, height: 30.w),
                6.verticalSpace,
                Opacity(
                  opacity: selected ? 1 : 0.5,
                  child: AppText(
                    label,
                    textAlign: TextAlign.center,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 2,
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
