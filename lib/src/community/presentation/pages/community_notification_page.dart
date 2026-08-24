part of '../../community.dart';

/// The community inbox: replies to your posts, and moderation notices.
class CommunityNotificationPage extends StatefulWidget {
  const CommunityNotificationPage({super.key});

  @override
  State<CommunityNotificationPage> createState() => _CommunityNotificationPageState();
}

class _CommunityNotificationPageState extends State<CommunityNotificationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cubit = context.read<CommunityNotificationCubit>();
    // Opening the inbox IS reading it — the badge clears here rather than
    // waiting for each row to be tapped.
    cubit.load().then((_) => cubit.markAllRead());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Paging from a scroll listener rather than from inside itemBuilder: asking
  /// for the next page while the list is building emits state mid-build.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<CommunityNotificationCubit>().load(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      appBar: _CommunityAppBar(title: l10n.notificationsTitle),
      body: BlocBuilder<CommunityNotificationCubit, CommunityNotificationState>(
        builder: (context, state) {
          if (state.status == CommunityStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _CommunityMessage(
                title: l10n.notificationsEmptyTitle,
                body: l10n.notificationsEmptyBody,
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return _NotificationRow(item: state.items[index]);
            },
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final CommunityNotificationEntity item;

  /// One line per kind. The actor's name is not carried on the row (the API
  /// stores an id, and resolving one name per row would be a query per row), so
  /// the copy is written to read without it — the post it points at supplies
  /// the context.
  String _label(BuildContext context) {
    final l10n = context.l10n.community;

    return switch (item.type) {
      CommunityNotificationType.commentOnPost => l10n.notificationCommentOnPost,
      CommunityNotificationType.replyToComment => l10n.notificationReplyToComment,
      CommunityNotificationType.officialReply => l10n.notificationOfficialReply,
      CommunityNotificationType.postHidden => l10n.notificationPostHidden,
      CommunityNotificationType.sanctionApplied => l10n.notificationSanction,
      CommunityNotificationType.unknown => l10n.notificationsTitle,
    };
  }

  bool get _isModeration =>
      item.type == CommunityNotificationType.postHidden ||
      item.type == CommunityNotificationType.sanctionApplied;

  @override
  Widget build(BuildContext context) {
    final postId = item.postId;

    return GestureDetector(
      onTap: postId == null || postId.isEmpty
          ? null
          : () => CommunityPostRoute(postId: postId).push(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppCustomColor.backgroundWhite
              : AppCustomColor.backgroundBrandSoft,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Icon(
              _isModeration ? Icons.gavel_outlined : Icons.mode_comment_outlined,
              size: 18.sp,
              color: _isModeration ? AppCustomColor.errorRed : AppCustomColor.streakActive,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    _label(context),
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
                  ),
                  SizedBox(height: 3.h),
                  AppText(
                    communityRelativeTime(context, item.createdAt),
                    style: AppStyle.text10.copyWith(color: AppCustomColor.communityMuted),
                  ),
                ],
              ),
            ),
            if (postId != null && postId.isNotEmpty)
              Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: AppCustomColor.communityMuted,
              ),
          ],
        ),
      ),
    );
  }
}
