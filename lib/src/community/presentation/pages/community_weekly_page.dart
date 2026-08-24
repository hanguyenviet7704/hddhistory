part of '../../community.dart';

/// The weekly question and its answers (design `S-05`).
///
/// Answers are ordinary comments on the question post, so everything below the
/// header is the same machinery as a normal thread.
class CommunityWeeklyPage extends StatelessWidget {
  const CommunityWeeklyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityPostCubit, CommunityPostState>(
      builder: (context, state) {
        final cubit = context.read<CommunityPostCubit>();
        final weekly = state.weekly;

        return Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          appBar: _CommunityAppBar(title: l10n.weeklyTitle),
          body: state.status == CommunityStatus.loading && weekly == null
              ? const Center(child: CircularProgressIndicator())
              : weekly == null
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _CommunityMessage(
                    // No open question is a real answer, not a failure.
                    title: l10n.weeklyNoneTitle,
                    body: l10n.weeklyNoneBody,
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _CommunityThreadList(
                        header: _WeeklyHeaderBlock(weekly: weekly),
                        state: state,
                      ),
                    ),
                    if (state.canComment)
                      CommunityComposerBar(
                        isSubmitting: state.isSubmitting,
                        replyingToName: state.replyTarget == null ? null : cubit.replyToName,
                        onCancelReply: cubit.cancelReply,
                        onSubmit: cubit.submitComment,
                        hintOverride: l10n.composerHintWeekly,
                      )
                    else
                      _ClosedComposerNote(state: state),
                  ],
                ),
        );
      },
    );
  }
}

class _WeeklyHeaderBlock extends StatelessWidget {
  const _WeeklyHeaderBlock({required this.weekly});

  final CommunityWeeklyEntity weekly;

  /// "TUẦN 34 · 18—24/08" — week number and the window it covers.
  ///
  /// The date range is what makes "còn 3 ngày" concrete; the feed card has room
  /// for only the week number, this screen has room for both.
  String _label(BuildContext context) {
    final l10n = context.l10n.community;
    final week = weekly.weekNumber;
    final base = week == null ? l10n.weeklyLabel : l10n.weeklyLabelWithWeek(week: week);

    final start = weekly.startsAt;
    final end = weekly.endsAt;
    if (start == null || end == null) return base;

    return '$base · ${start.parseString('dd/MM')}—${end.parseString('dd/MM')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final daysLeft = weekly.daysLeft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary50,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppCustomColor.communityWeeklyBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      _label(context),
                      style: AppStyle.textBold10.copyWith(
                        color: AppCustomColor.streakActive,
                        letterSpacing: 0.7,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (daysLeft != null && daysLeft > 0)
                    AppText(
                      l10n.weeklyDaysLeft(count: daysLeft),
                      style: AppStyle.text10.copyWith(color: AppCustomColor.communityMuted),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              AppText(
                weekly.title,
                style: AppStyle.textBold20.copyWith(
                  color: AppCustomColor.communityTopicHeading,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  // Solid brand disc with a white M — the team's mark here is a
                  // signature on the question, not a member avatar in a list.
                  Container(
                    width: 22.w,
                    height: 22.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.brandPrimary,
                    ),
                    child: AppText(
                      'M',
                      style: AppStyle.textBold8.copyWith(color: AppCustomColor.textWhite),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    l10n.officialAuthorName,
                    style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Outside the card on purpose: it is house guidance about answering,
        // not part of the question being asked.
        if (weekly.note.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: AppText(
              weekly.note,
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.communityMuted,
                height: 1.5,
              ),
            ),
          ),
        SizedBox(height: 18.h),
      ],
    );
  }
}
