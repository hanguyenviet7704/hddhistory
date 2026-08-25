part of '../../coach.dart';

class CoachMessageList extends StatefulWidget {
  final List<CoachMessage> messages;
  final bool typing;
  final CoachCourseInviteEntity? courseInvite;

  const CoachMessageList({
    super.key,
    required this.messages,
    required this.typing,
    this.courseInvite,
  });

  @override
  State<CoachMessageList> createState() => _CoachMessageListState();
}

class _CoachMessageListState extends State<CoachMessageList> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(covariant CoachMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length || widget.typing != oldWidget.typing) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ...widget.messages.map((m) => _Bubble(message: m)),
      if (widget.typing) const _TypingDots(),
      if (widget.courseInvite != null) _CourseInvite(invite: widget.courseInvite!),
    ];

    return ListView.separated(
      controller: _controller,
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 10.h),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, index) => children[index],
    );
  }
}

class _Bubble extends StatelessWidget {
  final CoachMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isCoach = message.isCoach;
    final width = MediaQuery.sizeOf(context).width;

    return Row(
      mainAxisAlignment: isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: width * 0.84),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: isCoach ? CoachStyle.surface : CoachStyle.userBubble,
            // The tail sits on the side the message came from: bottom-left for
            // the Coach, bottom-right for the reader.
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isCoach ? 5.r : 16.r),
              bottomRight: Radius.circular(isCoach ? 16.r : 5.r),
            ),
            boxShadow: CoachStyle.cardShadow,
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.55,
              color: isCoach ? CoachStyle.textPrimary : CoachStyle.surface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Three dots on the design's `cv-dot` rhythm — each one lifts and brightens
/// a beat after the last.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double t, int index) {
    final shifted = (t - index * 0.15) % 1.0;
    if (shifted >= 0.6) return 0;

    // 0 → 0.3 rises, 0.3 → 0.6 falls.
    return shifted < 0.3 ? shifted / 0.3 : 1 - (shifted - 0.3) / 0.3;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: CoachStyle.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(5.r),
              bottomRight: Radius.circular(16.r),
            ),
            boxShadow: CoachStyle.cardShadow,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = _phase(_controller.value, i);

                return Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 4.w),
                  child: Transform.translate(
                    offset: Offset(0, -4.h * phase),
                    child: Opacity(
                      opacity: 0.4 + 0.6 * phase,
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: CoachStyle.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// ③C — one course, offered.
///
/// One, never a list: a list is a catalogue, and the design is explicit that
/// this is an invitation rather than a verdict on what the reader just said.
/// The caption says so out loud, because a course card appearing right after
/// somebody describes a hard week reads as a diagnosis unless it is told not to.
class _CourseInvite extends StatelessWidget {
  final CoachCourseInviteEntity invite;

  const _CourseInvite({required this.invite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: CoachStyle.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: CoachStyle.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.coach.courseInviteTitle.toUpperCase(),
            style: CoachStyle.sectionLabel(size: 10.5),
          ),
          SizedBox(height: 4.h),
          Text(
            invite.title,
            style: TextStyle(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w700,
              height: 1.45,
              color: CoachStyle.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.l10n.coach.courseInviteCaption,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: CoachStyle.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
