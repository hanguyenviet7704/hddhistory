part of '../../../roleplay.dart';

class RoleplayConversationBubble extends StatelessWidget {
  final ConversationEntity conversation;
  final ConversationEntity? previousConversation;
  final RoleplayAudioController? audioController;

  const RoleplayConversationBubble({
    super.key,
    required this.conversation,
    this.previousConversation,
    required this.audioController,
  });

  bool get _isRight => conversation.position == RoleplayConversationPosition.right;
  bool get _isSamePerson {
    if (previousConversation == null) return false;
    return previousConversation!.avatar.id == conversation.avatar.id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: !_isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _RoleplayParticipantAvatar(conversation: conversation, isRight: _isRight, isSamePerson: _isSamePerson),
        8.verticalSpace,
        _RoleplayBubbleContent(
          isRight: _isRight,
          conversation: conversation,
          audioController: audioController,
        ),
      ],
    );
  }
}

class _RoleplayBubbleContent extends StatelessWidget {
  final bool isRight;
  final ConversationEntity conversation;
  final RoleplayAudioController? audioController;

  const _RoleplayBubbleContent({
    required this.isRight,
    required this.conversation,
    required this.audioController,
  });

  BorderRadius get _radius {
    final Radius tight = Radius.circular(4.r);
    final Radius relaxed = Radius.circular(20.r);

    if (isRight) {
      return BorderRadius.only(
        topLeft: relaxed,
        topRight: tight,
        bottomLeft: relaxed,
        bottomRight: relaxed,
      );
    }

    return BorderRadius.only(
      topLeft: tight,
      topRight: relaxed,
      bottomLeft: relaxed,
      bottomRight: relaxed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.78.sw,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: conversation.backgroundColor.toHexColor,
            borderRadius: _radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                conversation.content.text,
                style: AppStyle.text14.copyWith(
                  color: conversation.textColor.toHexColor,
                  height: 1.5,
                ),
                maxLines: 20,
              ),
              if (audioController?.hasAudio ?? false) ...[
                12.verticalSpace,
                RoleplayAudioButton(
                  controller: audioController,
                  iconColor: conversation.textColor.toHexColor,
                  dense: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleplayParticipantAvatar extends StatelessWidget {
  final ConversationEntity conversation;
  final bool isRight;
  final bool isSamePerson;

  const _RoleplayParticipantAvatar({
    required this.conversation,
    required this.isRight,
    required this.isSamePerson,
  });

  @override
  Widget build(BuildContext context) {
    if (isSamePerson) return SizedBox.shrink();

    Widget avatar = CacheNetworkGraphic(
      url: conversation.avatar.url,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(50.r),
      width: 28.w,
      height: 28.w,
    );

    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(isRight ? 12.w : 3.w, 3.w, isRight ? 3.w : 12.w, 3.w),
        decoration: BoxDecoration(color: conversation.backgroundColor.toHexColor, borderRadius: BorderRadius.circular(100.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) ...[
              avatar,
              8.horizontalSpace,
            ],
            AppText(
              conversation.avatar.name,
              style: AppStyle.textBold14.copyWith(
                color: conversation.textColor.toHexColor,
              ),
            ),
            if (isRight) ...[
              8.horizontalSpace,
              avatar,
            ],
          ],
        ),
      ),
    );
  }
}
