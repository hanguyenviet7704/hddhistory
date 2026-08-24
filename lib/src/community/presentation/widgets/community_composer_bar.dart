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
    this.replyingToName,
    this.onCancelReply,
    this.hintOverride,
  });

  final Future<bool> Function(String body) onSubmit;
  final bool isSubmitting;
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
    if (body.isEmpty || widget.isSubmitting) return;

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

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        // Nearly opaque rather than glass: this bar sits under the keyboard and
        // holds an input the reader is typing into — legibility beats letting
        // the background show through.
        color: studyThemeCardColor(context, opacity: 0.94),
        border: Border(top: BorderSide(color: AppCustomColor.borderDefault)),
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
                      style: AppStyle.text12.copyWith(color: AppCustomColor.communityMuted),
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
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
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
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundGray,
                      borderRadius: BorderRadius.circular(22.r),
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
                    width: 40.w,
                    height: 40.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.text.trim().isEmpty
                          ? AppCustomColor.buttonDisable
                          : AppCustomColor.brandPrimary,
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
                        : Icon(
                            Icons.send_rounded,
                            size: 18.sp,
                            color: _controller.text.trim().isEmpty
                                ? AppCustomColor.communityMuted
                                : AppCustomColor.textWhite,
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
