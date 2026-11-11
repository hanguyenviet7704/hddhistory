part of '../../spaced_review.dart';

/// Home's "Ôn tập hôm nay" entry. Present only while something is due and
/// askable; otherwise the whole slot, bottom spacing included, collapses to
/// zero height — no empty or loading card, the same rule `HomeBannerCard`
/// follows.
class SpacedReviewHomeCard extends StatelessWidget {
  const SpacedReviewHomeCard({super.key});

  static const Color _accent = Color(0xFFB5860F);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpacedReviewCubit, SpacedReviewState>(
      buildWhen: (previous, current) => previous.hasReviewAvailable != current.hasReviewAvailable || previous.sessionKeypointCount != current.sessionKeypointCount,
      builder: (context, state) {
        if (!state.hasReviewAvailable) return const SizedBox.shrink();

        final l10n = context.l10n.spacedReview;
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 22.h),
          child: Semantics(
            button: true,
            label: '${l10n.homeCardTitle}. ${l10n.homeCardSubtitle(total: state.sessionKeypointCount)}',
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('spaced-review-home-card'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<SpacedReviewCubit>().start();
                SpacedReviewQuestionRoute().push(context);
              },
              child: ThemedGlassCard(
                padding: EdgeInsets.all(16.w),
                radius: 20,
                shadow: [BoxShadow(color: const Color(0x0D252525), offset: Offset(0, 6.h), blurRadius: 18.r)],
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.history_edu_rounded, color: _accent, size: 24.w),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            l10n.homeCardTitle,
                            style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
                          ),
                          4.verticalSpace,
                          AppText(
                            l10n.homeCardSubtitle(total: state.sessionKeypointCount),
                            maxLines: 2,
                            style: AppStyle.text13.copyWith(color: const Color(0xFF5F6F86)),
                          ),
                        ],
                      ),
                    ),
                    8.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(100.r)),
                      child: AppText(
                        l10n.startButton,
                        style: AppStyle.text13.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
