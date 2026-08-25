part of '../../community.dart';

/// "Đề xuất phòng mới" (design `S-02`).
///
/// Shows the asks already open underneath the form, because the most useful
/// thing a reader can do here is usually back one instead of filing a fifth
/// copy of it — and the server merges an identical name into a vote anyway, so
/// showing them first makes that outcome expected rather than surprising.
void showCommunityRoomSuggestSheet(BuildContext context) {
  showDModalBottomSheet(
    initialChildSize: 0.72,
    maxChildSize: 0.92,
    contentPadding: EdgeInsets.zero,
    bodyWidget: const _CommunityRoomSuggestSheet(),
  );
}

class _CommunityRoomSuggestSheet extends StatefulWidget {
  const _CommunityRoomSuggestSheet();

  @override
  State<_CommunityRoomSuggestSheet> createState() =>
      _CommunityRoomSuggestSheetState();
}

class _CommunityRoomSuggestSheetState
    extends State<_CommunityRoomSuggestSheet> {
  static const int _maxNameLength = 40;
  static const int _maxDescriptionLength = 160;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<CommunityRoomSuggestionEntity> _suggestions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _votingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await AppDI.injector
        .get<GetCommunityRoomSuggestionsUseCase>()()
        .run();
    if (!mounted) return;

    result.fold(
      (_) => setState(() => _isLoading = false),
      (items) => setState(() {
        _suggestions = items;
        _isLoading = false;
      }),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final result = await AppDI.injector
        .get<CreateCommunityRoomSuggestionUseCase>()(
          name: name,
          description: _descriptionController.text.trim(),
        )
        .run();
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.fold(
      (exception) => DMessage.showMessage(
        message: _messageFor(context, exception),
        type: MessageType.error,
      ),
      (suggestion) {
        final l10n = context.l10n.community;
        Navigator.of(context).maybePop();
        DMessage.showMessage(
          // The server turns a duplicate name into a vote on the ask already
          // open. Saying "sent" then would be a lie about what happened.
          message: suggestion.mergedIntoExisting
              ? l10n.roomSuggestMerged
              : l10n.roomSuggestSent,
          type: MessageType.info,
        );
      },
    );
  }

  Future<void> _vote(CommunityRoomSuggestionEntity suggestion) async {
    if (suggestion.hasVoted || _votingId != null) return;

    setState(() => _votingId = suggestion.id);
    final result = await AppDI.injector
        .get<VoteCommunityRoomSuggestionUseCase>()(suggestion.id)
        .run();
    if (!mounted) return;

    setState(() => _votingId = null);

    result.fold(
      (exception) => DMessage.showMessage(
        message: _messageFor(context, exception),
        type: MessageType.error,
      ),
      (updated) => setState(() {
        _suggestions = _suggestions
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      }),
    );
  }

  /// The server's own refusals, said properly.
  ///
  /// These two are decisions ("you have three open already", "this one is
  /// closed"), not failures — showing the generic "chưa tải được" for them
  /// would tell the reader to retry something that will refuse again.
  String _messageFor(BuildContext context, AppException exception) {
    final l10n = context.l10n.community;
    final raw = exception.message ?? '';

    if (raw.contains('COMMUNITY_TOO_MANY_ROOM_SUGGESTIONS')) {
      return l10n.roomSuggestTooMany;
    }
    if (raw.contains('COMMUNITY_ROOM_SUGGESTION_CLOSED')) {
      return l10n.roomSuggestClosed;
    }

    return l10n.errorBody;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final canSubmit = _nameController.text.trim().isNotEmpty && !_isSubmitting;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              l10n.roomSuggestFormTitle,
              style: AppStyle.textBold18.copyWith(
                color: AppCustomColor.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            _FieldLabel(text: l10n.roomSuggestNameLabel),
            _SheetField(
              controller: _nameController,
              hint: l10n.roomSuggestNameHint,
              maxLength: _maxNameLength,
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 16.h),
            _FieldLabel(text: l10n.roomSuggestDescLabel),
            _SheetField(
              controller: _descriptionController,
              hint: l10n.roomSuggestDescHint,
              maxLength: _maxDescriptionLength,
              minLines: 3,
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: _SheetButton(
                    label: l10n.roomSuggestCancel,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _SheetButton(
                    label: l10n.roomSuggestSubmit,
                    isPrimary: true,
                    isBusy: _isSubmitting,
                    onTap: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              SizedBox(height: 24.h),
              const Center(child: CircularProgressIndicator.adaptive()),
            ] else if (_suggestions.isNotEmpty) ...[
              SizedBox(height: 26.h),
              AppText(
                l10n.roomSuggestOthersTitle,
                style: AppStyle.textBold14.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              ..._suggestions.map(
                (suggestion) => _SuggestionRow(
                  suggestion: suggestion,
                  isBusy: _votingId == suggestion.id,
                  onVote: () => _vote(suggestion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: AppText(
        text,
        style: AppStyle.textBold10.copyWith(
          color: AppCustomColor.communityMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final VoidCallback onChanged;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    final isFull = length >= maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(
              color: controller.text.isEmpty
                  ? AppCustomColor.borderDefault
                  : AppCustomColor.brandPrimary,
              width: controller.text.isEmpty ? 1 : 1.4,
            ),
          ),
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: minLines == 1 ? 1 : minLines + 1,
            maxLength: maxLength,
            // The field's own counter would sit under the box next to the one
            // this widget draws to the design's spec.
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            onChanged: (_) => onChanged(),
            style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppStyle.text14.copyWith(
                color: AppCustomColor.communityMuted,
              ),
            ),
          ),
        ),
        SizedBox(height: 5.h),
        AppText(
          '$length/$maxLength',
          style: AppStyle.textBold10.copyWith(
            color: isFull
                ? AppCustomColor.brandPrimary
                : AppCustomColor.communityMuted,
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isBusy;
    final background = isPrimary
        ? (isEnabled
              ? AppCustomColor.brandPrimary
              : AppCustomColor.brandPrimary.withValues(alpha: 0.4))
        : AppCustomColor.backgroundGray;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: isBusy
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            : AppText(
                label,
                style: AppStyle.textBold14.copyWith(
                  color: isPrimary
                      ? AppCustomColor.backgroundWhite
                      : AppCustomColor.streakTextMuted,
                ),
              ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.isBusy,
    required this.onVote,
  });

  final CommunityRoomSuggestionEntity suggestion;
  final bool isBusy;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  suggestion.name,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.textPrimary,
                  ),
                  maxLines: 2,
                ),
                if (suggestion.description.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  AppText(
                    suggestion.description,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.streakTextMuted,
                    ),
                    maxLines: 2,
                  ),
                ],
                SizedBox(height: 4.h),
                AppText(
                  l10n.roomSuggestVotes(count: suggestion.voteCount),
                  style: AppStyle.textBold10.copyWith(
                    color: AppCustomColor.communityMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: suggestion.hasVoted || isBusy ? null : onVote,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: suggestion.hasVoted
                    ? AppCustomColor.brandPrimary
                    : AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(99.r),
                border: Border.all(
                  color: suggestion.hasVoted
                      ? AppCustomColor.brandPrimary
                      : AppCustomColor.brandPrimary200,
                  width: 1.4,
                ),
              ),
              child: AppText(
                suggestion.hasVoted
                    ? l10n.roomSuggestVoted
                    : l10n.roomSuggestVote,
                style: AppStyle.textBold12.copyWith(
                  color: suggestion.hasVoted
                      ? AppCustomColor.backgroundWhite
                      : AppCustomColor.streakActive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
