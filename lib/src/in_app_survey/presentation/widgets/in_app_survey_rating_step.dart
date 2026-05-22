part of '../../in_app_survey.dart';

class InAppSurveyRatingStep extends StatefulWidget {
  const InAppSurveyRatingStep({
    super.key,
    required this.config,
    required this.onSelectBranch,
  });

  final InAppSurveyConfigEntity config;
  final ValueChanged<int> onSelectBranch;

  @override
  State<InAppSurveyRatingStep> createState() => _InAppSurveyRatingStepState();
}

class _InAppSurveyRatingStepState extends State<InAppSurveyRatingStep> {
  static const Duration _selectionVisibleDuration = Duration(milliseconds: 650);

  late final ValueNotifier<int?> _selectedIndexNotifier;

  @override
  void initState() {
    super.initState();
    _selectedIndexNotifier = ValueNotifier<int?>(null);
  }

  @override
  void didUpdateWidget(covariant InAppSurveyRatingStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _selectedIndexNotifier.value = null;
    }
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.config.branches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InAppSurveyTitle(_surveyText(widget.config.introQuestion.question)),
        2.verticalSpace,
        _InAppSurveyGuide(_surveyText(widget.config.introQuestion.guide)),
        20.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              branches.length,
              (index) => Expanded(
                child: _RatingBranchButton(
                  branch: branches[index],
                  index: index,
                  isFirst: index == 0,
                  isLast: index == branches.length - 1,
                  selectedIndexListenable: _selectedIndexNotifier,
                  onTap: () => _selectBranch(index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBranch(int index) async {
    if (_selectedIndexNotifier.value != null) return;
    _selectedIndexNotifier.value = index;

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(_selectionVisibleDuration);
    if (!mounted) return;
    widget.onSelectBranch(index);
  }
}

class _RatingBranchButton extends StatelessWidget {
  const _RatingBranchButton({
    required this.branch,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.selectedIndexListenable,
    required this.onTap,
  });

  final InAppSurveyBranchEntity branch;
  final int index;
  final bool isFirst;
  final bool isLast;
  final ValueListenable<int?> selectedIndexListenable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _label(context);

    return ValueListenableBuilder<int?>(
      valueListenable: selectedIndexListenable,
      builder: (context, selectedIndex, _) {
        final isSelected = selectedIndex == index;
        final isEnabled = selectedIndex == null;
        final emojiUrl = _emojiUrl(isSelected);

        return Semantics(
          button: true,
          enabled: isEnabled,
          selected: isSelected,
          label: label.isEmpty ? context.l10n.home.inAppSurveyRatingSemantics(rating: index + 1) : label,
          child: InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: isEnabled ? onTap : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 58.h, minWidth: 44.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44.w,
                    height: 44.w,
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.08 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: SizedBox(
                            key: ValueKey(emojiUrl),
                            width: 36.w,
                            height: 36.w,
                            child: _InAppSurveyRemoteGraphic(
                              url: emojiUrl,
                              size: 36.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (label.isNotEmpty) ...[
                    6.verticalSpace,
                    AppText(
                      label,
                      maxLines: 1,
                      enableFitScaleDown: true,
                      textAlign: TextAlign.center,
                      style: AppStyle.text14.copyWith(
                        color: isLast ? _InAppSurveyColors.textPrimary : _InAppSurveyColors.textTertiary,
                        height: 1.75,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _label(BuildContext context) {
    final name = branch.emoji.name?.trim() ?? '';
    if (isFirst) return name.isEmpty ? context.l10n.home.inAppSurveyRatingAwful : name;
    if (isLast) return name.isEmpty ? context.l10n.home.inAppSurveyRatingAmazing : name;
    return '';
  }

  String _emojiUrl(bool isSelected) {
    final lightUrl = branch.emoji.lightUrl.trim();
    final darkUrl = branch.emoji.darkUrl.trim();
    if (isSelected) return lightUrl.isNotEmpty ? lightUrl : darkUrl;
    return darkUrl.isNotEmpty ? darkUrl : lightUrl;
  }
}
