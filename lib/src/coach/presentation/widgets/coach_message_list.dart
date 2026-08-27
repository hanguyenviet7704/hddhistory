part of '../../coach.dart';

class CoachMessageList extends StatefulWidget {
  final List<CoachMessage> messages;
  final bool typing;

  /// Nhịp 3 — the two-column draft is a card IN the thread, under the Coach's
  /// line that introduced it, exactly as the design draws it. Null hides it.
  final CoachTwoColumns? draft;

  /// The one course the tail offers — a card in the thread under "Có một khoá
  /// gần với chuyện bạn vừa nói tới."; the composer holds its three chips.
  final CoachCourseCardEntity? course;

  const CoachMessageList({
    super.key,
    required this.messages,
    required this.typing,
    this.draft,
    this.course,
  });

  @override
  State<CoachMessageList> createState() => _CoachMessageListState();
}

class _CoachMessageListState extends State<CoachMessageList> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(covariant CoachMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        widget.typing != oldWidget.typing ||
        (widget.draft != null) != (oldWidget.draft != null) ||
        (widget.course != null) != (oldWidget.course != null)) {
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
      if (widget.draft != null) widget.draft!,
      if (widget.course != null) _CourseCard(course: widget.course!),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  // The scene's closing question is the line being answered, so
                  // it carries the weight in its own bubble.
                  fontWeight: message.emphasis ? FontWeight.w800 : FontWeight.w600,
                  height: 1.55,
                  color: isCoach ? CoachStyle.textPrimary : CoachStyle.surface,
                ),
              ),
            ],
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
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: CoachStyle.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(5.r),
              bottomRight: Radius.circular(16.r),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = _phase(_controller.value, i);

                return Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 5.w),
                  child: Transform.translate(
                    offset: Offset(0, -4.h * phase),
                    child: Opacity(
                      opacity: 0.4 + 0.6 * phase,
                      child: Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: CoachStyle.typingDot,
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

/// The one course the tail offers, as the design draws it: a lilac card with
/// the course's picture, its title, its author and its reach — the same three
/// facts the course rail shows, so the card reads as a door into a real course
/// and not as a verdict on what was just said.
///
/// One, never a list: "truy xuất MỘT khoá, không trả danh sách". The card does
/// nothing on tap; its three ways out are the chips under it, and every one of
/// them ranks the same.
class _CourseCard extends StatelessWidget {
  final CoachCourseCardEntity course;

  const _CourseCard({required this.course});

  String _reach(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';

    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final views = course.viewCount;
    // Why this course: a fact about the reader the server sent as a key. The
    // one line that makes the card read as the app having listened rather
    // than an advert — so it sits right under the title, before the meta row.
    final reason = coachCourseReason(context, course.reasonKey, course.reasonArgs);

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: CoachStyle.courseCardBackground,
        border: Border.all(color: CoachStyle.selectedBorderSoft),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 76.w,
              height: 76.w,
              child: ColoredBox(
                color: CoachStyle.courseImageFallback,
                child: course.image.isEmpty
                    ? Icon(Icons.menu_book_rounded, size: 26.w, color: CoachStyle.skin)
                    : CachedNetworkImage(
                        imageUrl: course.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(Icons.menu_book_rounded, size: 26.w, color: CoachStyle.skin),
                      ),
              ),
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  course.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: CoachStyle.textPrimary,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: CoachStyle.courseAuthor,
                    ),
                  ),
                ],
                if (course.author.isNotEmpty || views != null) ...[
                  SizedBox(height: 7.h),
                  Row(
                    children: [
                      if (course.author.isNotEmpty)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 13.r, color: CoachStyle.courseAuthor),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  course.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: CoachStyle.courseAuthor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (course.author.isNotEmpty && views != null) SizedBox(width: 12.w),
                      if (views != null) ...[
                        Icon(Icons.visibility_outlined, size: 13.r, color: CoachStyle.courseMeta),
                        SizedBox(width: 5.w),
                        Text(
                          _reach(views),
                          style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: CoachStyle.courseMeta),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
