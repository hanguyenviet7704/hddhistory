part of '../../../roleplay.dart';

class RoleplayConversationBubble extends StatelessWidget {
  final ConversationEntity conversation;
  final RoleplayAudioController? audioController;

  const RoleplayConversationBubble({
    super.key,
    required this.conversation,
    required this.audioController,
  });

  bool get _isRight => conversation.position == SectionConversationPosition.right;

  @override
  Widget build(BuildContext context) {
    final avatar = _RoleplayParticipantAvatar(conversation: conversation);
    final bubble = _RoleplayBubbleContent(
      isRight: _isRight,
      conversation: conversation,
      audioController: audioController,
    );

    return Column(
      crossAxisAlignment: !_isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: !_isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (!_isRight) ...[
              avatar,
              12.horizontalSpace,
            ],
            AppText(
              conversation.name,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w600,
                color: conversation.textColor.toHexColor == Colors.transparent ? AppCustomColor.textPrimary : conversation.textColor.toHexColor,
              ),
            ),
            if (_isRight) ...[
              12.horizontalSpace,
              avatar,
            ],
          ],
        ),
        8.verticalSpace,
        bubble,
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
    final Color bubbleColor = conversation.bubbleColor.toHexColor == Colors.transparent
        ? (isRight ? AppCustomColor.roleplayRightBubble : AppCustomColor.roleplayLeftBubble)
        : conversation.bubbleColor.toHexColor;
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
                conversation.content,
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

  const _RoleplayParticipantAvatar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final double size = 44.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: conversation.avartar.isEmpty
            ? Container(
                color: AppCustomColor.roleplayLeftBubble,
                child: Icon(
                  Icons.person,
                  color: AppCustomColor.textPrimary,
                  size: 22.w,
                ),
              )
            : DCachedImage(
                url: conversation.avartar,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
      ),
    );
  }
}

class RoleplayLeadingTextCard extends StatelessWidget {
  final LeadingTextEntity leadingText;
  final RoleplayAudioController? audioController;

  const RoleplayLeadingTextCard({
    super.key,
    required this.leadingText,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = leadingText.textColor.toHexColor == Colors.transparent ? AppCustomColor.textWhite : leadingText.textColor.toHexColor;
    final Color frameColor = leadingText.frameColor.toHexColor == Colors.transparent ? Colors.white.withValues(alpha: 0.4) : leadingText.frameColor.toHexColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayLeadingSurface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: frameColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                leadingText.content,
                textAlign: TextAlign.center,
                style: AppStyle.text12.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
              ),
              if (audioController?.hasAudio ?? false) ...[
                16.verticalSpace,
                RoleplayAudioButton(
                  controller: audioController,
                  iconColor: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RoleplayHintCard extends StatelessWidget {
  final HintEntity hint;

  const RoleplayHintCard({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    final Color textColor = hint.textColor.toHexColor == Colors.transparent ? AppCustomColor.grey69 : hint.textColor.toHexColor;

    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: AppCustomColor.roleplayHintBorder,
        strokeWidth: 1.2.w,
        dashPattern: [6.w, 4.w],
        radius: Radius.circular(20.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AppText(
          hint.content,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            color: textColor,
            height: 1.5,
          ),
          maxLines: 4,
        ),
      ),
    );
  }
}
