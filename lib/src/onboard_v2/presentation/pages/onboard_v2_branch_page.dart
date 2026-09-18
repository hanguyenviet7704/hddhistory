part of '../../onboard_v2.dart';

/// S4 — câu 1 "Lĩnh vực". Multi-select không giới hạn, GIỮ thứ tự chọn
/// (design.md §3.2 dựa vào thứ tự đó để chia đáp án câu 2).
///
/// Không còn enum dự phòng: taxonomy tải lỗi thì trang đứng ở inline error +
/// Thử lại — kèm một lối thoát "Bỏ qua, chọn giúp tôi" (skipTaxonomyQuestions)
/// để một máy mới cứng/offline lần đầu vẫn hoàn tất được onboarding.
class OnboardV2BranchPage extends StatelessWidget {
  const OnboardV2BranchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;
    final name = state.name.trim();
    // Config `paths.heading` KHÔNG có {name} — có chữ thì dùng nguyên, để trống
    // mới rơi về l10n (bản l10n mới chèn tên user).
    final headingPrefix = onbCopy(
      onboardData,
      'onboardingV3P4HeadingPrefix',
      fallback: onboardingL10n.onboardingV3P4HeadingPrefix(name: name.isEmpty ? onboardingL10n.onboardingV3You : name),
    );
    // Taxonomy lỗi hoặc tải xong mà rỗng: cả hai đều là ngõ cụt không có Thử
    // lại nào tự sửa được (offline lần đầu, taxonomy chưa seed/import) — phải
    // có lối thoát ngoài Retry.
    final isTaxonomyBroken =
        state.taxonomyStatus == OnboardV2TaxonomyStatus.failure ||
        (state.taxonomyStatus == OnboardV2TaxonomyStatus.success && state.taxonomy.selectableBranches.isEmpty);

    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 3,
        totalSegments: _onboardV2TotalProgressSegments,
        pageStep: OnboardV2PageStep.p4Branches,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueBranches ? cubit.continueFromP4Branches : null,
        secondaryLabel: isTaxonomyBroken ? onboardingL10n.onboardingV3SkipQuestions : null,
        onSecondaryPressed: isTaxonomyBroken ? cubit.skipTaxonomyQuestions : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            headingPrefix,
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: onboardV2HeadingStyle(fontSize: 24).copyWith(color: AppCustomColor.textPrimary),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV3P4HeadingHighlight', fallback: onboardingL10n.onboardingV3P4HeadingHighlight),
            style: onboardV2HeadingStyle(fontSize: 24),
          ),
          12.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P4Helper', fallback: onboardingL10n.onboardingV3P4Helper),
            overflow: TextOverflow.visible,
            style: onboardV2SubtitleStyle(),
          ),
          28.verticalSpace,
          if (state.taxonomyStatus == OnboardV2TaxonomyStatus.loading || state.taxonomyStatus == OnboardV2TaxonomyStatus.initial)
            const Center(child: CircularProgressIndicator())
          else if (state.taxonomyStatus == OnboardV2TaxonomyStatus.failure)
            OnboardV2InlineError(
              message: state.taxonomyErrorMessage ?? onboardingL10n.onboardingV3TaxonomyLoadError,
              onRetry: () => unawaited(cubit.loadTaxonomy()),
            )
          // Taxonomy tải được nhưng không nhánh nào `isSelectable && isActive`
          // (admin tắt hết / import lỗi): vẫn phải cho lối Thử lại, nếu không
          // user kẹt với danh sách rỗng và CTA tắt vĩnh viễn.
          else if (state.taxonomy.selectableBranches.isEmpty)
            OnboardV2InlineError(
              message: onboardingL10n.onboardingV3TaxonomyLoadError,
              onRetry: () => unawaited(cubit.loadTaxonomy()),
            )
          else
            ...state.taxonomy.selectableBranches.map((branch) {
              final iconUrl = branch.iconUrl.trim();
              return Padding(
                key: ValueKey('onboard_v2_branch_${branch.code}'),
                padding: EdgeInsets.only(bottom: 12.h),
                child: OnboardV2SelectableOptionRow(
                  label: branch.label.text,
                  subtitle: branch.subtitle.text,
                  iconPath: iconUrl.isNotEmpty ? iconUrl : null,
                  selected: state.selectedBranchCodes.contains(branch.code),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  onTap: () => cubit.toggleBranch(branch.code),
                ),
              );
            }),
        ],
      ),
    );
  }
}
