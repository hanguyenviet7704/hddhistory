part of '../../community.dart';

/// A group chat room (design `S-03 · Hội bàn tròn`).
///
/// A sheet with a rounded top rather than a full page: the design opens it OVER
/// the forum, and the reader is meant to feel they can drop it again — the room
/// is a place they step into, not a screen they navigated to.
///
/// The list is reversed, which is what makes a chat behave: new lines appear at
/// the bottom without a scroll jump, and "load older" is the top of the reversed
/// viewport rather than an index the screen has to hold on to.
class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key, required this.room});

  /// The room's SLUG — the app names the room rather than carrying its id.
  final String room;

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CommunityChatCubit>().open(widget.room);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Reversed list: maxScrollExtent is the OLDEST end.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<CommunityChatCubit>().loadOlder();
    }
  }

  Future<void> _send() async {
    final cubit = context.read<CommunityChatCubit>();
    if (!await communityRequireAccount(context, cubit.state.memberStatus)) return;

    final body = _controller.text;
    if (body.trim().isEmpty) return;
    if (cubit.state.isSending || cubit.state.isCoolingDown) return;

    // Cleared before the round trip: the optimistic line is already on screen,
    // and leaving the text in the field invites a second send.
    _controller.clear();
    setState(() {});

    final sent = await cubit.send(body);
    if (sent || !mounted) return;

    // The optimistic line is pulled back on failure, so without this the words
    // simply disappear — and the one refusal worth explaining (writing too fast)
    // would look like the app losing messages.
    DMessage.showMessage(
      message: cubit.state.errorMessage ?? context.l10n.community.errorBody,
      type: MessageType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityChatCubit, CommunityChatState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ChatHeader(room: state.room),
                Expanded(
                  child: state.status == CommunityStatus.loading && state.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _ChatTranscript(state: state, controller: _scrollController),
                ),
                _ChatComposer(
                  controller: _controller,
                  focusNode: _focusNode,
                  isSending: state.isSending,
                  isCoolingDown: state.isCoolingDown,
                  onChanged: () => setState(() {}),
                  onSend: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grab handle, close, the room's face, and how many people are in it.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.room});

  final CommunityChatRoomEntity? room;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final onlineCount = room?.onlineCount ?? 0;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: studyThemeOnBg(context, AppCustomColor.communityRule)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: 38.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: CommunityGlyph(
                    AppAsset.svg.app.icCommunityClose,
                    size: 21,
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                ),
                SizedBox(width: 11.w),
                const CommunityChatMark(size: 36, radius: 12, glyphSize: 21),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        room?.name ?? l10n.chatTitle,
                        style: AppStyle.textBold14.copyWith(
                          fontSize: 14.5.sp,
                          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                          height: 1.25,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppCustomColor.communityRoomInkGreen,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          AppText(
                            l10n.chatOnline(count: onlineCount),
                            style: AppStyle.text12.copyWith(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ChatTranscript extends StatelessWidget {
  const _ChatTranscript({required this.state, required this.controller});

  final CommunityChatState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    if (state.messages.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: _CommunityMessage(title: l10n.chatEmptyTitle, body: l10n.chatEmptyBody),
      );
    }

    // Reversed so index 0 is the newest line at the bottom.
    final rows = state.messages.reversed.toList();

    return ListView.separated(
      controller: controller,
      reverse: true,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      itemCount: rows.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        // Past the oldest row: the day chip, or the spinner fetching more.
        if (index == rows.length) {
          return state.isLoadingMore
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : (state.hasMore ? const SizedBox.shrink() : const _ChatDayChip());
        }

        final message = rows[index];

        return message.isMine
            ? _MyChatBubble(message: message)
            : _OtherChatBubble(message: message);
      },
    );
  }
}

/// "Hôm nay" — the only day marker the design draws, at the top of the room.
class _ChatDayChip extends StatelessWidget {
  const _ChatDayChip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 22.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppCustomColor.textPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AppText(
          context.l10n.community.chatToday,
          style: AppStyle.textBold10.copyWith(
            fontSize: 10.5.sp,
            color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
          ),
        ),
      ),
    );
  }
}

/// Someone else's line: avatar, glass bubble with a tail on the left, and the
/// heart chip under it when the room has reacted.
class _OtherChatBubble extends StatelessWidget {
  const _OtherChatBubble({required this.message});

  final CommunityChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityChatCubit>();
    final name = switch (message.author) {
      _ when message.author.isOfficial => l10n.officialAuthorName,
      _ when message.author.isAnonymous => l10n.anonymousAuthorName,
      _ when message.author.name.isEmpty => l10n.deletedAuthorName,
      _ => message.author.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // Bottom-aligned: the avatar sits at the foot of the bubble, beside
          // the tail, however tall the message runs.
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CommunityAvatar(author: message.author, size: 30),
            SizedBox(width: 9.w),
            Flexible(
              child: GestureDetector(
                onDoubleTap: () => cubit.toggleLike(message),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 268.w),
                  padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 11.h),
                  decoration: BoxDecoration(
                    color: studyThemeCardColor(context, opacity: 0.86),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.r),
                      topRight: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(6.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppText(
                              name,
                              style: AppStyle.textBold12.copyWith(
                                color: AppCustomColor.textPrimary,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (message.isModerator) ...[
                            SizedBox(width: 7.w),
                            const _ChatModeratorPill(),
                          ],
                          SizedBox(width: 7.w),
                          AppText(
                            communityChatClock(message.createdAt),
                            style: AppStyle.text12.copyWith(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        message.body,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.communityCommentInk,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message.likeCount > 0)
          Padding(
            // Lines up with the bubble's left edge, past the avatar.
            padding: EdgeInsets.only(left: 41.w, top: 6.h),
            child: GestureDetector(
              onTap: () => cubit.toggleLike(message),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 24.h,
                padding: EdgeInsets.symmetric(horizontal: 9.w),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: AppCustomColor.communityChatChipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CommunityGlyph(
                      AppAsset.svg.app.icCommunityHeartFill,
                      size: 12,
                      color: AppCustomColor.communityChatBadge,
                    ),
                    SizedBox(width: 5.w),
                    AppText(
                      '${message.likeCount}',
                      style: AppStyle.textBold12.copyWith(
                        fontSize: 11.sp,
                        color: AppCustomColor.communityAuthorName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatModeratorPill extends StatelessWidget {
  const _ChatModeratorPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: AppText(
        context.l10n.community.chatModerator,
        style: AppStyle.textBold8.copyWith(
          fontSize: 9.sp,
          color: AppCustomColor.brandPrimary,
        ),
      ),
    );
  }
}

/// My own line: solid brand, tail on the right, and the read receipt under it.
class _MyChatBubble extends StatelessWidget {
  const _MyChatBubble({required this.message});

  final CommunityChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 270.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            // A line still in flight is dimmed rather than hidden: the reader
            // sees what they said AND that it has not landed yet.
            color: AppCustomColor.brandPrimary.withValues(
              alpha: message.isPending ? 0.55 : 1,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomRight: Radius.circular(6.r),
              bottomLeft: Radius.circular(18.r),
            ),
          ),
          child: AppText(
            message.body,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textWhite,
              height: 1.55,
            ),
          ),
        ),
        SizedBox(height: 5.h),
        AppText(
          message.isPending
              ? l10n.chatSending
              : (message.isSeen
                    ? l10n.chatSeenAt(time: communityChatClock(message.createdAt))
                    : communityChatClock(message.createdAt)),
          style: AppStyle.text12.copyWith(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
            color: studyThemeOnBg(context, AppCustomColor.communityMuted),
          ),
        ),
      ],
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isCoolingDown,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;

  /// The two-second pause after a line lands. The button greys out for it rather
  /// than showing a countdown: it is over before a number would be read.
  final bool isCoolingDown;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final canSend = controller.text.trim().isNotEmpty && !isSending && !isCoolingDown;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 11.h, 14.w, 11.h),
      decoration: BoxDecoration(
        // Near-opaque, like the thread composer: it holds an input under the
        // keyboard, and legibility wins on this one strip.
        color: studyThemeCardColor(context, opacity: 0.94),
        border: Border(top: BorderSide(color: AppCustomColor.communityRule)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 42.h),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: AppCustomColor.borderSecondary),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: AppStyle.text14.copyWith(
                    fontSize: 13.5.sp,
                    color: AppCustomColor.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l10n.chatHint,
                    hintStyle: AppStyle.text14.copyWith(
                      fontSize: 13.5.sp,
                      color: AppCustomColor.communityMuted,
                    ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ),
            SizedBox(width: 9.w),
            GestureDetector(
              onTap: onSend,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 42.w,
                height: 42.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canSend ? AppCustomColor.brandPrimary : AppCustomColor.buttonDisable,
                ),
                child: isSending
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppCustomColor.textWhite,
                        ),
                      )
                    : CommunityGlyph(
                        AppAsset.svg.app.icCommunityArrowRight,
                        size: 18,
                        color: canSend
                            ? AppCustomColor.textWhite
                            : AppCustomColor.communityMuted,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
