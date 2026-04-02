part of '../../output_practice.dart';

class OutputPracticeTimelineList extends StatelessWidget {
  const OutputPracticeTimelineList({
    super.key,
    required this.controller,
    required this.items,
    required this.activeActionChips,
    required this.conversationTransitionStatus,
    required this.assistantName,
    required this.assistantAvatarUrl,
    required this.userName,
    required this.helperLabel,
    required this.showThinking,
    required this.thinkingLabel,
    required this.historyErrorText,
    required this.historyRetryLabel,
    required this.onRetryHistory,
    required this.roomErrorText,
    required this.roomRetryLabel,
    required this.onRetryRoom,
    required this.showJumpToLatest,
    required this.jumpToLatestLabel,
    required this.conversationTransitionLabel,
    required this.onJumpToLatest,
    required this.onRetryFailedMessage,
    required this.onChipTap,
    required this.resolveChipLabel,
  });

  final ScrollController controller;
  final List<OutputPracticeTimelineItem> items;
  final List<OutputPracticeActionChipVm> activeActionChips;
  final OutputPracticeConversationTransitionStatus conversationTransitionStatus;
  final String assistantName;
  final String assistantAvatarUrl;
  final String userName;
  final String helperLabel;
  final bool showThinking;
  final String thinkingLabel;
  final String? historyErrorText;
  final String historyRetryLabel;
  final VoidCallback onRetryHistory;
  final String? roomErrorText;
  final String roomRetryLabel;
  final VoidCallback onRetryRoom;
  final bool showJumpToLatest;
  final String jumpToLatestLabel;
  final String conversationTransitionLabel;
  final VoidCallback onJumpToLatest;
  final VoidCallback onRetryFailedMessage;
  final ValueChanged<OutputPracticeActionChipVm> onChipTap;
  final String Function(OutputPracticeActionChipVm chip) resolveChipLabel;

  @override
  Widget build(BuildContext context) {
    final chipStack = activeActionChips.isEmpty
        ? const SizedBox(
            key: ValueKey('output_practice_action_chips_empty'),
          )
        : OutputPracticeActionChipStack(
            key: ValueKey(
              'output_practice_action_chips_${activeActionChips.map((chip) => chip.id).join('_')}',
            ),
            helperLabel: helperLabel,
            chips: activeActionChips,
            onChipTap: onChipTap,
            resolveLabel: resolveChipLabel,
          );
    final bottomSlot = switch (conversationTransitionStatus) {
      OutputPracticeConversationTransitionStatus.startingNewConversation => _OutputPracticeConversationTransitionIndicator(
        key: const ValueKey('output_practice_conversation_transition_starting'),
        label: conversationTransitionLabel,
      ),
      OutputPracticeConversationTransitionStatus.idle => chipStack,
    };

    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          opacity: conversationTransitionStatus == OutputPracticeConversationTransitionStatus.startingNewConversation ? 0.74 : 1,
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            children: [
              if (historyErrorText != null) ...[
                _OutputPracticeRetryBanner(
                  text: historyErrorText!,
                  actionLabel: historyRetryLabel,
                  onTap: onRetryHistory,
                ),
                16.verticalSpace,
              ],
              if (roomErrorText != null) ...[
                _OutputPracticeRetryBanner(
                  text: roomErrorText!,
                  actionLabel: roomRetryLabel,
                  onTap: onRetryRoom,
                ),
                16.verticalSpace,
              ],
              ...items.map((item) {
                final child = item.isAssistant
                    ? OutputPracticeAssistantBubble(
                        name: assistantName,
                        avatarUrl: assistantAvatarUrl,
                        content: item.content,
                      )
                    : OutputPracticeUserBubble(
                        content: item.content,
                        userLabel: userName,
                        deliveryStatus: item.deliveryStatus,
                        onRetry: item.deliveryStatus == OutputPracticeDeliveryStatus.failed ? onRetryFailedMessage : null,
                      );
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: child,
                );
              }),
              if (showThinking) ...[
                OutputPracticeThinkingRow(
                  name: assistantName,
                  avatarUrl: assistantAvatarUrl,
                  label: thinkingLabel,
                ),
                16.verticalSpace,
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: bottomSlot,
              ),
            ],
          ),
        ),
        if (showJumpToLatest)
          Positioned(
            right: 20.w,
            bottom: 16.h,
            child: GestureDetector(
              onTap: onJumpToLatest,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16.w,
                      color: const Color(0xFF554FF0),
                    ),
                    6.horizontalSpace,
                    AppText(
                      jumpToLatestLabel,
                      style: AppStyle.text12.copyWith(
                        color: const Color(0xFF554FF0),
                        fontWeight: FontWeight.w700,
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

class _OutputPracticeConversationTransitionIndicator extends StatelessWidget {
  const _OutputPracticeConversationTransitionIndicator({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14.w,
              height: 14.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF554FF0)),
              ),
            ),
            10.horizontalSpace,
            AppText(
              label,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF554FF0),
                fontWeight: FontWeight.w700,
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputPracticeRetryBanner extends StatelessWidget {
  const _OutputPracticeRetryBanner({
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.75,
            ),
          ),
          8.verticalSpace,
          GestureDetector(
            onTap: onTap,
            child: AppText(
              actionLabel,
              style: AppStyle.text14.copyWith(
                color: const Color(0xFF554FF0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
