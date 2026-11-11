part of '../../community.dart';

/// The way into the group chat, bottom-right of the forum (design `S-03`).
///
/// Sits above the floating nav pill rather than beside the compose "+": the
/// chat is a place, not an action on the feed, and the design keeps the two
/// apart. Shown on the hub tabs only — inside a post the reader is already
/// somewhere.
class CommunityChatFab extends StatelessWidget {
  const CommunityChatFab({super.key, required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.community.chatTitle,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.communityChatMarkEnd.withValues(alpha: 0.36),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          // Clip.none: the badge rides outside the tile's corner.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CommunityChatMark(size: 58, radius: 20, glyphSize: 34),
              if (unreadCount > 0)
                Positioned(
                  top: -3.h,
                  right: -3.w,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    height: 18.w,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99.r),
                      color: AppCustomColor.communityChatBadge,
                      border: Border.all(color: AppCustomColor.backgroundWhite, width: 2),
                    ),
                    child: AppText(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: AppStyle.textBold8.copyWith(
                        fontSize: 9.5.sp,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The FAB plus the one call that feeds its badge.
///
/// Loads the room itself instead of widening [CommunityFeedCubit]: the badge is
/// the only thing the hub needs to know about the chat, and the feed's state has
/// no other reason to carry a chat room. Refreshes on every mount, which is
/// every time the reader comes back to the hub.
class CommunityChatFabLoader extends StatefulWidget {
  const CommunityChatFabLoader({super.key, required this.room});

  final String room;

  @override
  State<CommunityChatFabLoader> createState() => _CommunityChatFabLoaderState();
}

class _CommunityChatFabLoaderState extends State<CommunityChatFabLoader> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AppDI.injector
        .get<GetCommunityChatRoomUseCase>()(widget.room)
        .run();
    if (!mounted) return;

    result.fold(
      // A room that cannot be read just shows no badge: the button still works,
      // and an error toast on the feed for a count nobody asked for is noise.
      (_) {},
      (room) => setState(() => _unread = room.unreadCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommunityChatFab(
      unreadCount: _unread,
      onTap: () async {
        await CommunityChatRoute(room: widget.room).push(context);
        if (mounted) _load();
      },
    );
  }
}

/// The one room that ships. Named here rather than at the call site so the
/// slug lives in exactly one place.
const String communityDefaultChatRoom = 'hoi-ban-tron';
