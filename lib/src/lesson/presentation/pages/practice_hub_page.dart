part of '../../lesson.dart';

/// Practice hub — "pick how you want to practise" (design "3 · Learning" →
/// Practice, `_MeUp App` pin `practicehub`). Reached from the lesson-complete
/// screen's "Practice now".
///
/// Three modes, exactly the design's list: Quiz is live and opens the keypoint's
/// own question deck ([KeypointQuizPage]); Roleplay and Short video ship as
/// visible-but-disabled rows with the design's "Coming soon" chip — they are on
/// the design sheet, so hiding them would misrepresent the roadmap, and the
/// server already reserves their practice methods (`learningItem.type` video /
/// roleplay through `habit_practices` overrides).
class PracticeHubPage extends StatelessWidget {
  final String title;
  final List<QuestionEntity> questions;

  const PracticeHubPage({super.key, required this.title, required this.questions});

  /// Pushed imperatively rather than through a typed go_router route because it
  /// carries entities, and the repo has no `$extra` typed routes to follow.
  static Future<void> push(
    BuildContext context, {
    required String title,
    required List<QuestionEntity> questions,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PracticeHubPage(title: title, questions: questions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = context.l10n.lesson;

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
          child: Padding(
            // Design: 52px top under the status bar, 20 sides, 30 bottom.
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _closeButton(context),
                34.verticalSpace,
                AppText(
                  lesson.practiceHubTitle,
                  // Design 26/700.
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                ),
                6.verticalSpace,
                AppText(
                  lesson.practiceHubSubtitle,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: studyThemeOnBg(context, AppCustomColor.practiceModeSubtext),
                  ),
                ),
                22.verticalSpace,
                // A keypoint with no playable questions shows Quiz as "Coming
                // soon" like the other two modes (user call, 2026-08-07) — a
                // tappable row opening onto an empty deck would be a dead end
                // dressed as an option, and hiding it entirely made the hub
                // look broken.
                _modeCard(
                  context,
                  tint: AppCustomColor.brandPrimary50,
                  icon: Icons.quiz_outlined,
                  iconColor: AppCustomColor.brandPrimary,
                  title: lesson.practiceModeQuizTitle,
                  subtitle: lesson.practiceModeQuizSubtitle,
                  onTap: questions.isEmpty
                      ? null
                      : () {
                          AppHaptic.select();
                          KeypointQuizPage.push(context, title: title, questions: questions);
                        },
                ),
                14.verticalSpace,
                _modeCard(
                  context,
                  tint: AppCustomColor.practiceRoleplayTint,
                  icon: Icons.forum_outlined,
                  iconColor: AppCustomColor.practiceRoleplayIcon,
                  title: lesson.practiceModeRoleplayTitle,
                  subtitle: lesson.practiceModeRoleplaySubtitle,
                ),
                14.verticalSpace,
                _modeCard(
                  context,
                  tint: AppCustomColor.kpResultCorrectSurface,
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: AppCustomColor.successGreen,
                  title: lesson.practiceModeVideoTitle,
                  subtitle: lesson.practiceModeVideoSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design's `rgba(13,18,28,.06)` circle reads on the design's flat light
  /// page, but this page sits on [ThemedBackground] — over a photo it
  /// disappears ("dấu x mờ"). The keypoint header solved exactly this with
  /// [KeypointHeaderButtonChrome] (white .9 circle, dark icon), so the X wears
  /// the same chrome as the screen the reader just came from.
  Widget _closeButton(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.common.close,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          Navigator.of(context).pop();
        },
        behavior: HitTestBehavior.opaque,
        child: KeypointHeaderButtonChrome(
          child: Icon(Icons.close, size: 18.w, color: KeypointHeaderChrome.icon),
        ),
      ),
    );
  }

  /// One mode row (design: white card radius 22, icon plate 56 radius 18, title
  /// 16.5/700 + sub 13/500, then a chevron when live or the "Coming soon" chip
  /// when not). A row without [onTap] IS the coming-soon state.
  Widget _modeCard(
    BuildContext context, {
    required Color tint,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final isLive = onTap != null;

    return Semantics(
      button: isLive,
      child: Material(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(22.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(color: const Color(0x142B226E), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(18.r)),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 30.w, color: iconColor),
                ),
                16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        // Design 16.5/700.
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 16.5.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                      5.verticalSpace,
                      AppText(
                        subtitle,
                        maxLines: 2,
                        style: AppStyle.text13.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: AppCustomColor.practiceModeSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                if (isLive)
                  Icon(Icons.chevron_right_rounded, size: 22.w, color: AppCustomColor.practiceChevron)
                else
                  Container(
                    height: 26.h,
                    padding: EdgeInsets.symmetric(horizontal: 11.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppCustomColor.practiceComingSoonChip,
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    child: AppText(
                      context.l10n.lesson.practiceComingSoon,
                      // Design 11.5/700.
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppCustomColor.practiceModeSubtext,
                      ),
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
