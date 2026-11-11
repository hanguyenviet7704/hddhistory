part of '../../../../lesson.dart';

class DocumentExplanationWidget extends StatefulWidget {
  final String title;
  final List<ExplanationOptionEntity> options;
  final String? selectedOptionKey;
  final ValueChanged<String?>? onSelectionChanged;

  const DocumentExplanationWidget({
    super.key,
    this.title = '',
    required this.options,
    this.selectedOptionKey,
    this.onSelectionChanged,
  });

  @override
  State<DocumentExplanationWidget> createState() => _DocumentExplanationWidgetState();
}

class _DocumentExplanationWidgetState extends State<DocumentExplanationWidget> {
  String? selectedOptionKey;

  bool get _isControlled => widget.onSelectionChanged != null;

  String? get _resolvedSelectedOptionKey => _isControlled ? widget.selectedOptionKey : selectedOptionKey;

  @override
  void initState() {
    super.initState();
    selectedOptionKey = widget.selectedOptionKey;
  }

  @override
  void didUpdateWidget(covariant DocumentExplanationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.options, widget.options) && !_isControlled) {
      selectedOptionKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle = widget.title.isNotEmpty;

    if (!hasTitle && widget.options.isEmpty) return const SizedBox.shrink();

    final idCounts = <int, int>{};
    for (final option in widget.options) {
      idCounts.update(option.id, (count) => count + 1, ifAbsent: () => 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle) ...[
          AppText(
            widget.title,
            key: const ValueKey('document-explanation-title'),
            maxLines: 5,
            style: AppStyle.text20.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          if (widget.options.isNotEmpty) 16.verticalSpace,
        ],
        ...List.generate(widget.options.length, (index) {
          final option = widget.options[index];
          final optionKey = _resolveOptionKey(index, option, idCounts);
          final isSelected = _resolvedSelectedOptionKey == optionKey;

          return Padding(
            padding: EdgeInsets.only(bottom: index == widget.options.length - 1 ? 0 : 12.h),
            child: _DocumentExplanationOptionCard(
              key: ValueKey('document-explanation-card-$index'),
              option: option,
              isSelected: isSelected,
              onTap: () => _toggleOption(optionKey),
            ),
          );
        }),
      ],
    );
  }

  String _resolveOptionKey(
    int index,
    ExplanationOptionEntity option,
    Map<int, int> idCounts,
  ) {
    final isStableId = option.id > 0 && idCounts[option.id] == 1;
    return isStableId ? 'id:${option.id}' : 'index:$index';
  }

  void _toggleOption(String optionKey) {
    // Tapping a theory/reading option to reveal (or hide) its explanation — a
    // light tap so the reading content feels interactive, not just scrollable.
    AppHaptic.select();
    final nextSelectedOptionKey = _resolvedSelectedOptionKey == optionKey ? null : optionKey;

    if (_isControlled) {
      widget.onSelectionChanged?.call(nextSelectedOptionKey);
      return;
    }

    setState(() {
      selectedOptionKey = nextSelectedOptionKey;
    });
  }
}

class _DocumentExplanationOptionCard extends StatelessWidget {
  final ExplanationOptionEntity option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocumentExplanationOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = option.icon.isNotEmpty;
    final explanationText = option.explanation.text;
    final showExplanation = isSelected && explanationText.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
            width: 2.w,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasIcon) ...[
                  CacheNetworkGraphic(
                    url: option.icon,
                    width: 24.w,
                    height: 24.w,
                    fit: BoxFit.contain,
                  ),
                  12.horizontalSpace,
                ],
                Expanded(
                  child: AppText(
                    option.value.text,
                    maxLines: 10,
                    style: AppStyle.text14.copyWith(
                      color: isSelected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                    ),
                  ),
                ),
              ],
            ),
            if (showExplanation) ...[
              4.verticalSpace,
              Padding(
                padding: EdgeInsets.only(left: hasIcon ? 36.w : 0),
                child: AppText(
                  explanationText,
                  key: ValueKey('document-explanation-detail-${option.id}-${option.value.text}'),
                  maxLines: 10,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
