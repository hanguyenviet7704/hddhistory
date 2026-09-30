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
  /// A positioned list, not a plain [ListView].
  ///
  /// Jumping to a pinned message means scrolling to an INDEX whose height
  /// nobody knows — chat bubbles are as tall as their text. `ensureVisible`
  /// only reaches widgets that are already built, which the target of a jump
  /// into history never is. This package is already a dependency and already
  /// used by the course list.
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_onPositions);
    context.read<CommunityChatCubit>().open(widget.room);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositions);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Reversed list: the HIGHEST index is the oldest line, so nearing it is
  // nearing the top of the room.
  void _onPositions() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty || !mounted) return;

    final deepest = positions.map((position) => position.index).reduce(math.max);
    final total = context.read<CommunityChatCubit>().state.messages.length;
    if (deepest >= total - 3) {
      context.read<CommunityChatCubit>().loadOlder();
    }
  }

  /// Puts the flashed message on screen once the cubit has decided which one it
  /// is — after a jump that had to fetch a window, the list has only just been
  /// replaced, so this runs on the frame after that state lands.
  void _scrollToFlashed(String messageId, List<CommunityChatMessageEntity> messages) {
    final rows = messages.reversed.toList();
    final index = rows.indexWhere((message) => message.id == messageId);
    if (index < 0 || !_itemScrollController.isAttached) return;

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      // A third of the way up rather than flush to the edge: a pinned line
      // reads as an answer to something, and the lines around it are the point.
      alignment: 0.3,
    );
  }

  Future<void> _openGuide(CommunityChatGuideEntity guide) => showCommunityChatGuideSheet(
    context,
    guide: guide,
    // The openers are the part of the rules that actually does work: most
    // people who open them were not worried about breaking anything, they
    // just did not know how to start. So one lands in the composer, with
    // the keyboard up, rather than being something to memorise.
    onUseStarter: (starter) {
      _controller.text = starter;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _focusNode.requestFocus();
      setState(() {});
    },
  );

  void _jumpTo(CommunityChatMessageEntity message) => context.read<CommunityChatCubit>().jumpToMessage(message.id);

  void _jumpToId(String messageId) => context.read<CommunityChatCubit>().jumpToMessage(messageId);

  Future<void> _openMessageActions(
    CommunityChatMessageEntity message,
    Rect anchor,
  ) {
    final cubit = context.read<CommunityChatCubit>();

    return showCommunityChatMessageActions(
      context,
      message: message,
      anchor: anchor,
      onReply: () {
        cubit.startReply(message);
        _focusNode.requestFocus();
      },
      onReport: () => showCommunityReportSheet(
        context,
        onSubmit: (reason) => cubit.reportMessage(message, reason),
      ),
    );
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
    return BlocConsumer<CommunityChatCubit, CommunityChatState>(
      // Only when the flashed message CHANGES to something: the same id staying
      // put must not re-scroll under a reader who has since moved.
      listenWhen: (previous, current) => current.flashedMessageId != null && previous.flashedMessageId != current.flashedMessageId,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToFlashed(state.flashedMessageId!, state.messages);
        });
      },
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
                _ChatHeader(
                  room: state.room,
                  // No guide written means no button, rather than a button that
                  // opens an empty sheet.
                  onGuide: state.hasGuide ? () => _openGuide(state.guide!) : null,
                ),
                CommunityChatPinBar(
                  pinned: state.pinned,
                  onJump: _jumpTo,
                  onOpenList: () => showCommunityChatPinSheet(
                    context,
                    pinned: state.pinned,
                    onJump: _jumpTo,
                  ),
                ),
                Expanded(
                  child: state.status == CommunityStatus.loading && state.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            _ChatTranscript(
                              state: state,
                              itemScrollController: _itemScrollController,
                              positionsListener: _positionsListener,
                              onMessageActions: _openMessageActions,
                              onJumpToQuoted: _jumpToId,
                            ),
                            // Only after a jump landed somewhere with newer
                            // lines after it. Without this the reader is
                            // stranded in last month with no way back but
                            // closing the room.
                            if (state.isInHistory)
                              Positioned(
                                right: 16.w,
                                bottom: 12.h,
                                child: _ChatBackToLatestButton(
                                  onTap: () => context.read<CommunityChatCubit>().backToLatest(),
                                ),
                              ),
                          ],
                        ),
                ),
                _ChatComposer(
                  controller: _controller,
                  focusNode: _focusNode,
                  isSending: state.isSending,
                  isCoolingDown: state.isCoolingDown,
                  onChanged: () => setState(() {}),
                  onSend: _send,
                  replyTarget: state.replyTarget,
                  onCancelReply: () => context.read<CommunityChatCubit>().cancelReply(),
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
  const _ChatHeader({required this.room, this.onGuide});

  final CommunityChatRoomEntity? room;

  /// Null when no house rules have been written — the button is then absent
  /// rather than opening an empty sheet.
  final VoidCallback? onGuide;

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
                if (onGuide != null)
                  Semantics(
                    button: true,
                    label: l10n.chatGuideTitle,
                    // Đĩa trắng, không phải glyph trần: thiết kế cho nút này
                    // nền rgba(255,255,255,.88) kèm bóng mờ, và đó không phải
                    // trang trí — header nằm trên ẢNH NỀN theo chủ đề người
                    // dùng chọn, nên một nét tím mảnh đặt thẳng lên ảnh có thể
                    // biến mất hoàn toàn. Nền trắng là thứ giữ cho nó luôn
                    // thấy được, dù phía sau là tuyết hay là rừng.
                    child: GestureDetector(
                      onTap: onGuide,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        margin: EdgeInsets.only(left: 6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppCustomColor.textWhite.withValues(alpha: 0.88),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D121C).withValues(alpha: 0.07),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 17.sp,
                          color: _pinViolet,
                        ),
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

class _ChatTranscript extends StatelessWidget {
  const _ChatTranscript({
    required this.state,
    required this.itemScrollController,
    required this.positionsListener,
    required this.onMessageActions,
    required this.onJumpToQuoted,
  });

  final CommunityChatState state;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener positionsListener;

  /// Long press on a line. Held by the page because the menu's "Trả lời" has to
  /// put the keyboard up, and the focus node lives there.
  /// Tin nhắn cùng hình chữ nhật TOÀN CỤC của hàng nó nằm — menu neo dưới đó.
  final void Function(CommunityChatMessageEntity message, Rect anchor) onMessageActions;

  /// Tap on a quote strip — takes the reader to the line being answered.
  final ValueChanged<String> onJumpToQuoted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    if (state.messages.isEmpty) {
      // A failed load and an empty room are NOT the same thing, and until now
      // they drew the same screen: the room 404'd for two hours while this said
      // "Chưa có ai nhắn gì", which reads as "the room is fine, nobody has
      // spoken" — the one message guaranteed to send someone looking in the
      // wrong place.
      if (state.status == CommunityStatus.failure) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _CommunityMessage(
            title: l10n.errorTitle,
            body: state.errorMessage ?? l10n.errorBody,
            actionLabel: l10n.retry,
            onAction: () => context.read<CommunityChatCubit>().retry(),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: _CommunityMessage(title: l10n.chatEmptyTitle, body: l10n.chatEmptyBody),
      );
    }

    // Reversed so index 0 is the newest line at the bottom.
    final rows = state.messages.reversed.toList();

    return ScrollablePositionedList.separated(
      itemScrollController: itemScrollController,
      itemPositionsListener: positionsListener,
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
        final isFlashed = state.flashedMessageId == message.id;

        return message.isMine
            // Tin của chính mình KHÔNG có menu: thiết kế chỉ vẽ nó ở nhánh
            // `m.isOther`, và hai mục trong đó đều vô nghĩa với tin của mình —
            // trả lời chính mình, hoặc báo cáo chính mình.
            ? _MyChatBubble(
                message: message,
                isFlashed: isFlashed,
                onJumpToQuoted: onJumpToQuoted,
              )
            : _OtherChatBubble(
                message: message,
                isFlashed: isFlashed,
                onMenu: (anchor) => onMessageActions(message, anchor),
                onJumpToQuoted: onJumpToQuoted,
              );
      },
    );
  }
}

/// The way back to the running transcript after a jump into history.
///
/// Only drawn while the list is a window from the past. The design does not
/// show one — it has no real history to get lost in — but without it a reader
/// who taps a months-old pin can only escape by closing the room.
class _ChatBackToLatestButton extends StatelessWidget {
  const _ChatBackToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.community.chatBackToLatest;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(99.r),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.textPrimary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                size: 15.sp,
                color: AppCustomColor.textPrimary,
              ),
              SizedBox(width: 6.w),
              AppText(
                label,
                style: AppStyle.textBold14.copyWith(
                  fontSize: 12.sp,
                  color: AppCustomColor.textPrimary,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
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
  const _OtherChatBubble({
    required this.message,
    this.isFlashed = false,
    required this.onMenu,
    required this.onJumpToQuoted,
  });

  /// Mở menu, kèm hình chữ nhật toàn cục của hàng này để menu neo dưới nó.
  void _openMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    onMenu(box.localToGlobal(Offset.zero) & box.size);
  }

  final CommunityChatMessageEntity message;

  /// The ~2s after a jump landed here.
  final bool isFlashed;
  final ValueChanged<Rect> onMenu;
  final ValueChanged<String> onJumpToQuoted;

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
                // CHẠM mở menu — thiết kế gắn `m.onMsgMore` thẳng vào cú click
                // trên bong bóng. Nhấn giữ vẫn nhận, cho người đã quen tay.
                //
                // `context` ở đây là element của chính widget này, nên render
                // object của nó là CẢ HÀNG (avatar + bong bóng): đúng gốc toạ
                // độ mà thiết kế đo `left:41` từ đó.
                onTap: () => _openMenu(context),
                onLongPress: () => _openMenu(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
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
                    boxShadow: _bubbleShadow(message, isFlashed),
                    border: isFlashed ? flashedBubbleBorder() : null,
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
                          // Last in the meta row, after the time — where the
                          // design puts it. Inside the bubble body (where this
                          // first went) it reads as part of the message.
                          if (message.isPinned) ...[
                            SizedBox(width: 6.w),
                            Icon(Icons.push_pin_rounded, size: 13.sp, color: pinInk),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (message.replyTo != null)
                        _ChatQuote(
                          reply: message.replyTo!,
                          onDark: false,
                          onTap: () => onJumpToQuoted(message.replyTo!.id),
                        ),
                      AppText(
                        message.body,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.communityCommentInk,
                          height: 1.55,
                        ),
                        // [AppText] clamps at 10 lines and ellipsises by
                        // DEFAULT, so a long message was being cut off in the
                        // room with no way to read the rest of it.
                        maxLines: 100,
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

/// The lift under a bubble.
///
/// Three states, and the order matters: a pinned line that a jump just landed
/// on wears the FLASH, not its resting shadow — the stronger one is the answer
/// to the tap, and the tap is what the reader is waiting on.
List<BoxShadow>? _bubbleShadow(CommunityChatMessageEntity message, bool isFlashed) {
  if (isFlashed) return flashedBubbleShadow();
  if (message.isPinned) return pinnedBubbleShadow();

  return null;
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
  const _MyChatBubble({
    required this.message,
    this.isFlashed = false,
    required this.onJumpToQuoted,
  });

  final CommunityChatMessageEntity message;

  /// The ~2s after a jump landed here.
  final bool isFlashed;
  final ValueChanged<String> onJumpToQuoted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
            boxShadow: _bubbleShadow(message, isFlashed),
            border: isFlashed ? flashedBubbleBorder() : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null)
                _ChatQuote(
                  reply: message.replyTo!,
                  onDark: true,
                  onTap: () => onJumpToQuoted(message.replyTo!.id),
                ),
              AppText(
                message.body,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textWhite,
                  height: 1.55,
                ),
                maxLines: 100,
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // My own line has no meta row inside the bubble — the clock lives
            // under it — so the pin joins the clock here.
            if (message.isPinned) ...[
              Icon(Icons.push_pin_rounded, size: 13.sp, color: pinInk),
              SizedBox(width: 5.w),
            ],
            AppText(
              message.isPending ? l10n.chatSending : (message.isSeen ? l10n.chatSeenAt(time: communityChatClock(message.createdAt)) : communityChatClock(message.createdAt)),
              style: AppStyle.text12.copyWith(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: studyThemeOnBg(context, AppCustomColor.communityMuted),
              ),
            ),
          ],
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
    this.replyTarget,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;

  /// The two-second pause after a line lands. The button greys out for it rather
  /// than showing a countdown: it is over before a number would be read.
  final bool isCoolingDown;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  /// The line being answered — draws the quote strip above the field.
  final CommunityChatMessageEntity? replyTarget;
  final VoidCallback onCancelReply;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null)
              _ComposerReplyStrip(
                message: replyTarget!,
                onCancel: onCancelReply,
              ),
            Row(
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
                            color: canSend ? AppCustomColor.textWhite : AppCustomColor.communityMuted,
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

/// The quote above the composer while a reply is being written.
///
/// Carries the ✕ rather than relying on a back gesture: the reply target is
/// invisible state, and state you cannot see needs a way out you can.
class _ComposerReplyStrip extends StatelessWidget {
  const _ComposerReplyStrip({required this.message, required this.onCancel});

  final CommunityChatMessageEntity message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final name = switch (message.author) {
      _ when message.author.isOfficial => l10n.officialAuthorName,
      _ when message.author.isAnonymous => l10n.anonymousAuthorName,
      _ when message.author.name.isEmpty => l10n.deletedAuthorName,
      _ => message.author.name,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 6.w, 8.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12.r),
        border: Border(left: BorderSide(color: pinInk, width: 2.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${l10n.replyingTo} $name',
                  style: AppStyle.text12.copyWith(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: pinInk,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 1.h),
                AppText(
                  message.body,
                  style: AppStyle.text12.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppCustomColor.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.replyingTo,
            child: IconButton(
              onPressed: onCancel,
              icon: Icon(
                Icons.close_rounded,
                size: 17.sp,
                color: AppCustomColor.streakTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The quoted line drawn inside a reply's bubble. Tapping it goes there.
class _ChatQuote extends StatelessWidget {
  const _ChatQuote({
    required this.reply,
    required this.onTap,
    required this.onDark,
  });

  final CommunityChatReplyEntity reply;
  final VoidCallback onTap;

  /// True inside my own (solid brand) bubble, where the quote has to be drawn
  /// in light ink on a translucent white wash instead of the reverse.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final author = reply.author;
    final name = switch (author) {
      null => '',
      _ when author.isOfficial => l10n.officialAuthorName,
      _ when author.isAnonymous => l10n.anonymousAuthorName,
      _ when author.name.isEmpty => l10n.deletedAuthorName,
      _ => author.name,
    };
    // Chữ trong khối trích dẫn LUÔN sẫm, kể cả trong bong bóng tím.
    //
    // Hai lần trước đều sai cùng một kiểu: giữ khối trích dẫn trong gam tím
    // của bong bóng (trắng 16% rồi đen 18%) và viết chữ trắng lên đó. Cùng gam
    // thì mắt không tách được hai lớp, dù đậm nhạt khác nhau. Lối ra là đổi
    // GAM: khối trích dẫn thành thẻ sáng, chữ sẫm — giống hệt khối trích dẫn
    // trong bong bóng của người khác, chỉ nền trắng hơn để nổi trên tím.
    final ink = AppCustomColor.textSecondary;

    return GestureDetector(
      // A removed line has nowhere to go, so it is not a target.
      onTap: reply.isRemoved ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.fromLTRB(9.w, 6.h, 9.w, 7.h),
        decoration: BoxDecoration(
          // Trắng gần đặc trên bong bóng tím; tím rất nhạt trên bong bóng kính.
          color: onDark
              ? AppCustomColor.textWhite.withValues(alpha: 0.95)
              : const Color(0xFFFDFAF3),
          borderRadius: BorderRadius.circular(9.r),
          // Vạch tím ở cả hai trường hợp: trên thẻ trắng nó là thứ nói rằng
          // đây là lời được dẫn lại, không phải một tin nhắn khác.
          border: Border(left: BorderSide(color: pinInk, width: 2.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              AppText(
                name,
                style: AppStyle.text12.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: pinInk,
                ),
                maxLines: 1,
              ),
            AppText(
              reply.isRemoved ? l10n.chatReplyRemoved : reply.body,
              style: AppStyle.text12.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                fontStyle: reply.isRemoved ? FontStyle.italic : FontStyle.normal,
                color: ink.withValues(alpha: reply.isRemoved ? 0.7 : 1),
                height: 1.4,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
