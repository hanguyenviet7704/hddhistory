part of '../../output_practice.dart';

class OutputPracticeTimelineList extends StatelessWidget {
  const OutputPracticeTimelineList({
    super.key,
    required this.controller,
    required this.items,
    required this.activeActionChips,
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
    required this.onRetryFailedMessage,
    required this.onChipTap,
    required this.resolveChipLabel,
  });

  final ScrollController controller;
  final List<OutputPracticeTimelineItem> items;
  final List<OutputPracticeActionChipVm> activeActionChips;
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
  final VoidCallback onRetryFailedMessage;
  final ValueChanged<OutputPracticeActionChipVm> onChipTap;
  final String Function(OutputPracticeActionChipVm chip) resolveChipLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        if (activeActionChips.isNotEmpty)
          OutputPracticeActionChipStack(
            helperLabel: helperLabel,
            chips: activeActionChips,
            onChipTap: onChipTap,
            resolveLabel: resolveChipLabel,
          ),
      ],
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
