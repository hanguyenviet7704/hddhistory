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

  bool get _isRight => conversation.position == SectionConversationPosition.right;
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
    final Color bubbleColor = conversation.backgroundColor.toHexColor == Colors.transparent
        ? (isRight ? AppCustomColor.roleplayRightBubble : AppCustomColor.roleplayLeftBubble)
        : conversation.backgroundColor.toHexColor;
    final Color textColor = conversation.textColor.toHexColor == Colors.transparent ? AppCustomColor.textPrimary : conversation.textColor.toHexColor;

    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.78.sw,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: _radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                conversation.content.text,
                style: AppStyle.text14.copyWith(
                  color: textColor,
                  height: 1.5,
                ),
                maxLines: 20,
              ),
              if (audioController?.hasAudio ?? false) ...[
                12.verticalSpace,
                RoleplayAudioButton(
                  controller: audioController,
                  iconColor: textColor,
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
    
    Widget avatar = DCachedImage(
      url: conversation.avatar.url,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(50.r),
      width: 44.w,
      height: 44.w,
    );

    return Row(
      mainAxisAlignment: !isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (!isRight) ...[
          avatar,
          12.horizontalSpace,
        ],
        AppText(
          conversation.avatar.name,
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w600,
            color: conversation.textColor.toHexColor == Colors.transparent ? AppCustomColor.textPrimary : conversation.textColor.toHexColor,
          ),
        ),
        if (isRight) ...[
          12.horizontalSpace,
          avatar,
        ],
      ],
    );
  }
}
