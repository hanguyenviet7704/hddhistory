part of '../../community.dart';

/// The comment composer pinned to the bottom of a thread (design `S-04`).
///
/// When a reply is in progress it shows the "Đang trả lời X" strip with a way
/// out, because a reply sent to the wrong person is the one mistake this screen
/// can make that cannot be undone.
class CommunityComposerBar extends StatefulWidget {
  const CommunityComposerBar({
    super.key,
    required this.onSubmit,
    required this.isSubmitting,
    this.isCoolingDown = false,
    this.replyingToName,
    this.onCancelReply,
    this.hintOverride,
  });

  final Future<bool> Function(String body) onSubmit;
  final bool isSubmitting;

  /// The short pause after a comment lands. The button greys out for it rather
  /// than showing a countdown: it is over before a number would be read.
  final bool isCoolingDown;
  final String? replyingToName;
  final VoidCallback? onCancelReply;
  final String? hintOverride;

  @override
  State<CommunityComposerBar> createState() => _CommunityComposerBarState();
}

class _CommunityComposerBarState extends State<CommunityComposerBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(CommunityComposerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Starting a reply from a comment's "trả lời" should put the cursor in the
    // field — otherwise the strip appears and nothing else happens.
    final startedReply =
        oldWidget.replyingToName != widget.replyingToName && widget.replyingToName != null;
    if (startedReply) _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || widget.isSubmitting || widget.isCoolingDown) return;

    final sent = await widget.onSubmit(body);
    if (!sent || !mounted) return;

    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final replyingTo = widget.replyingToName;
    final isReplying = replyingTo != null && replyingTo.isNotEmpty;
    final canSend =
        _controller.text.trim().isNotEmpty && !widget.isSubmitting && !widget.isCoolingDown;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        // Nearly opaque rather than transparent: this bar sits under the
        // keyboard and holds an input being typed into — legibility beats
        // letting the background through, on this one strip.
        color: studyThemeCardColor(context, opacity: 0.94),
        border: const Border(top: BorderSide(color: AppCustomColor.communityRule)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReplying)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    AppText(
                      l10n.replyingTo,
                      style: AppStyle.text12.copyWith(
                        color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: AppText(
                        replyingTo,
                        style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary),
                        maxLines: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      behavior: HitTestBehavior.opaque,
                      child: CommunityGlyph(
                        AppAsset.svg.app.icCommunityClose,
                        size: 14,
                        color: AppCustomColor.communityMuted,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: 44.h),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      // A lighter pill on the bar, as in the design — it reads
                      // as the one place to type rather than as a second
                      // background.
                      color: AppCustomColor.backgroundWhite.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(99.r),
                      border: Border.all(
                        color: isReplying
                            ? AppCustomColor.brandPrimary
                            : AppCustomColor.borderSecondary,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: isReplying
                            ? l10n.composerHintReply
                            : (widget.hintOverride ?? l10n.composerHintComment),
                        hintStyle: AppStyle.text14.copyWith(
                          color: AppCustomColor.communityMuted,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: _submit,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend
                          ? AppCustomColor.brandPrimary
                          : AppCustomColor.buttonDisable,
                    ),
                    child: widget.isSubmitting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppCustomColor.textWhite,
                            ),
                          )
                        : CommunityGlyph(
                            AppAsset.svg.app.icCommunitySend,
                            size: 19,
                            color: canSend
                                ? AppCustomColor.textWhite
                                : AppCustomColor.communityMuted,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
