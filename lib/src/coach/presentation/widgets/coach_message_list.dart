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

  /// The card's ways out — "Học ngay" (also the whole card body), "Lưu lại",
  /// and the ✕. Null while a turn is in flight or on a replayed card.
  final VoidCallback? onCourseTap;
  final VoidCallback? onCourseSave;
  final VoidCallback? onCourseClose;

  /// "Luyện cảnh khó hơn" — the alternative to taking the course.
  final VoidCallback? onCourseHarder;

  /// ⟨Phương án⟩ / the mood row, rendered inside the thread right under the
  /// Coach's line — the design's option screens have no composer at all.
  final Widget? options;

  const CoachMessageList({
    super.key,
    required this.messages,
    required this.typing,
    this.draft,
    this.course,
    this.onCourseTap,
    this.onCourseSave,
    this.onCourseClose,
    this.onCourseHarder,
    this.options,
  });

  @override
  State<CoachMessageList> createState() => _CoachMessageListState();
}

class _CoachMessageListState extends State<CoachMessageList> with WidgetsBindingObserver {
  final _controller = ScrollController();

  /// The keyboard inset last seen, logical pixels — to tell opening from closing.
  double _lastInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Đường này vẫn chạy khi danh sách sinh ra đã có sẵn cả cuộc hội thoại —
    // lượt vừa về, cộng với mọi phiên cũ được phát lại phía trên nếu là phiên
    // nối tiếp. Trước 2026-09-09 đó là đường DUY NHẤT: sheet để vòng xoay suốt
    // lúc `opening` rồi mới thay danh sách vào, nên không có update nào theo
    // sau và cái hook cuộn-khi-đổi cũ chẳng bao giờ chạy, để người đọc đứng
    // trên đỉnh lịch sử (owner 2026-09-05: "khi bấm vào coach thì luôn scroll
    // đến đoạn chat hiện tại"). Giờ lúc `opening` sheet đã dựng sẵn danh sách
    // rỗng với chấm "đang gõ", nên lần đầu có bài thường tới qua
    // `didUpdateWidget` — nhánh đó gọi đúng `_settleToEnd()` này.
    if (widget.messages.isNotEmpty) _settleToEnd();
  }

  /// The keyboard. The sheet shrinks under it (AnimatedPadding, 160ms) but the
  /// list keeps its offset, so the newest lines sit hidden behind the keys
  /// until the reader scrolls by hand. Opening the keyboard now follows the
  /// conversation down; closing it leaves the reader where they are.
  @override
  void didChangeMetrics() {
    final view = View.of(context);
    final inset = view.viewInsets.bottom / view.devicePixelRatio;
    final opened = inset > _lastInset + 1;
    _lastInset = inset;

    if (!opened) return;
    // After the sheet's own 160ms resize, or maxScrollExtent is still moving.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scrollToEnd();
    });
  }

  @override
  void didUpdateWidget(covariant CoachMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        widget.typing != oldWidget.typing ||
        (widget.draft != null) != (oldWidget.draft != null) ||
        (widget.course != null) != (oldWidget.course != null) ||
        (widget.options != null) != (oldWidget.options != null)) {
      // A first fill that did arrive as an update (the safety panel giving way
      // to the thread, say) must LAND at the bottom rather than scroll down
      // through the history in front of the reader.
      if (oldWidget.messages.isEmpty && widget.messages.isNotEmpty) {
        _settleToEnd();
      } else {
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  /// Puts the list on its LAST line and keeps putting it there until the extent
  /// stops moving.
  ///
  /// A lazily-built [ListView] only ESTIMATES `maxScrollExtent` for the rows it
  /// has not laid out yet, working from the average of the ones it has. Jumping
  /// once therefore stops short of the true bottom, and stops shorter the more
  /// history there is — which is precisely the case the reader opens the sheet
  /// in. Each jump lays out more rows and sharpens the estimate, so repeat
  /// until two frames agree on it.
  void _settleToEnd({int frames = 8, double lastExtent = -1}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;

      final extent = _controller.position.maxScrollExtent;
      if (_controller.offset != extent) _controller.jumpTo(extent);
      // Bounded: an extent that never settles (an image still resolving its
      // own height, say) must not keep scheduling frames for the whole session.
      if (frames > 0 && extent != lastExtent) {
        _settleToEnd(frames: frames - 1, lastExtent: extent);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ...widget.messages.map((m) => _Bubble(message: m)),
      if (widget.typing) const _TypingDots(),
      if (widget.draft != null) widget.draft!,
      if (widget.course != null)
        _CourseCard(
          course: widget.course!,
          onOpen: widget.onCourseTap,
          onSave: widget.onCourseSave,
          onClose: widget.onCourseClose,
          onHarder: widget.onCourseHarder,
        ),
      if (widget.options != null) widget.options!,
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
    // The line between two sessions — a label on a hairline, not a bubble.
    if (message.divider) {
      return Row(
        children: [
          Expanded(child: Container(height: 1, color: CoachStyle.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              message.text,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: CoachStyle.textMuted),
            ),
          ),
          Expanded(child: Container(height: 1, color: CoachStyle.border)),
        ],
      );
    }

    final isCoach = message.isCoach;
    final width = MediaQuery.sizeOf(context).width;
    // Only ever set on a Coach-side line — the reader's own bubble is never
    // labelled, and a label on the purple bubble would read as them being
    // impersonated.
    final speaker = isCoach ? message.speaker?.trim() : null;

    // Every heading inside a bubble — the scene's "Với thói quen:" and the
    // roleplay partner's name alike. One object rather than two identical
    // literals: they ARE the same thing, and keeping them apart is what let
    // the speaker label quietly become its own style.
    final headingStyle = TextStyle(
      fontSize: 13.5.sp,
      fontWeight: FontWeight.w800,
      height: 1.55,
      color: isCoach ? CoachStyle.textPrimary : CoachStyle.surface,
    );

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
              // Tầng 3 — the scene's other person is talking, not the Coach.
              //
              // Owner 2026-09-05: without this the roleplay bubbles and the
              // Coach's own bubbles were the same white box, so the reader
              // could not tell Hằng answering back from the Coach commenting
              // on the scene. `speaker` has travelled from the model all the
              // way to CoachMessage since tầng 3 shipped — it was only ever
              // missing HERE, at the last step.
              //
              // Drawn as the SAME heading as "Tôi có tình huống:" below, and
              // through the same [headingStyle] so the two cannot drift apart
              // again: shipped with its own size, its own violet and a bullet,
              // which made one bubble in the thread speak a private visual
              // language (owner, 2026-09-05: "sao lại một mình 1 kiểu").
              if (speaker != null && speaker.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    speaker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headingStyle,
                  ),
                ),
              // The scene's little headings — "Với thói quen:", "Tôi có tình
              // huống:" — bold, above their own paragraph.
              if (message.title != null && message.title!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(message.title!, style: headingStyle),
                ),
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

  /// The card's ways out, as the design draws them: "Học ngay" filled,
  /// "Lưu lại" outlined, ✕ in the corner. Tapping the body is "Học ngay" too.
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  /// The other way forward: another scene about the same habit, one rung
  /// harder. Its own full-width row under the pair, because it is not a third
  /// way of dealing with the course — it is the alternative to taking it.
  final VoidCallback? onHarder;

  const _CourseCard({
    required this.course,
    this.onOpen,
    this.onSave,
    this.onClose,
    this.onHarder,
  });

  String _reach(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';

    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final views = course.viewCount;
    // Why this course: the one line that makes the card read as the app having
    // listened rather than an advert. It heads the card, beside the ✕.
    final reason = coachCourseReason(context, course.reasonKey, course.reasonArgs);

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: CoachStyle.courseCardBackground,
          border: Border.all(color: CoachStyle.selectedBorderSoft),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (reason == null || reason.isEmpty) ? course.title : reason,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: const Color(0xFF5B54A8),
                    ),
                  ),
                ),
                if (onClose != null) ...[
                  SizedBox(width: 8.w),
                  Semantics(
                    button: true,
                    label: l10n.courseCardClose,
                    child: GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE1DCF6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.close_rounded, size: 14.w, color: const Color(0xFF6A63B8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            Row(
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
            if (onOpen != null || onSave != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _CourseCardButton(
                      label: l10n.courseOpen,
                      filled: true,
                      onTap: onOpen,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _CourseCardButton(
                      label: l10n.courseCardSave,
                      filled: false,
                      onTap: onSave,
                    ),
                  ),
                ],
              ),
            ],
            if (onHarder != null) ...[
              SizedBox(height: 8.h),
              _CourseCardButton(
                label: l10n.courseHarderScene,
                filled: false,
                onTap: onHarder,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The card's two ways in: filled for "Học ngay", outlined for "Lưu lại" —
/// equal width, equal weight, exactly as the design draws them.
class _CourseCardButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _CourseCardButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? CoachStyle.skin : CoachStyle.surface,
          border: filled ? null : Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: filled ? CoachStyle.surface : CoachStyle.selectedText,
          ),
        ),
      ),
    );
  }
}
