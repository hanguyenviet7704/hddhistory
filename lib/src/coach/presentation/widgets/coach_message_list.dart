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

  /// Tầng 4 — the rubric read on the scene just finished, as a card in the
  /// thread under "Mình bước ra khỏi tình huống một chút."; the composer holds
  /// its two chips.
  final CoachSceneScoreEntity? score;

  const CoachMessageList({
    super.key,
    required this.messages,
    required this.typing,
    this.draft,
    this.course,
    this.score,
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
        (widget.course != null) != (oldWidget.course != null) ||
        (widget.score != null) != (oldWidget.score != null)) {
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
      if (widget.score != null) _ScoreCard(score: widget.score!),
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
              // Tầng 3 — this line was said by the scene's other person, so
              // their name sits above it. Without the label the reader gets a
              // demand in the Coach's bubble and reads it as the Coach's.
              // A bold heading — "Với thói quen:", "Tôi có tình huống:".
              if (message.title != null && message.title!.isNotEmpty) ...[
                Text(
                  message.title!,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                    color: CoachStyle.selectedText,
                  ),
                ),
                SizedBox(height: 3.h),
              ],
              if (message.speaker != null && message.speaker!.isNotEmpty) ...[
                Text(
                  message.speaker!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: CoachStyle.textMuted,
                  ),
                ),
                SizedBox(height: 4.h),
              ],
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

/// Tầng 4 "Reflect" — the rubric read on the scene just finished.
///
/// A card in the thread rather than a screen of its own: the assessment belongs
/// to the conversation that earned it, and a full-page report would turn a
/// two-minute practice into a test result. The bars are the rubric the SKILL
/// defines, so their labels arrive from the server already in the reader's
/// language — this widget never knows which criteria a habit uses.
class _ScoreCard extends StatelessWidget {
  final CoachSceneScoreEntity score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final skill = score.skill;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: CoachStyle.courseCardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.score.title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: CoachStyle.selectedText,
                  ),
                ),
              ),
              // The number is the mean of the bars below, never a grade on the
              // reader — the wording around it does that work.
              Text(
                _oneDecimal(score.overall),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: CoachStyle.userBubble,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 2.h),
                child: Text(
                  l10n.score.outOf,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.score.level(level: score.level.toString()),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: CoachStyle.textMuted,
            ),
          ),
          SizedBox(height: 12.h),
          ...score.criteria.map(
            (c) => Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: _Criterion(criterion: c),
            ),
          ),
          if (score.strength != null)
            _ScoreNote(label: l10n.score.strength, text: score.strength!, tone: _NoteTone.good),
          if (score.improve != null)
            _ScoreNote(label: l10n.score.improve, text: score.improve!, tone: _NoteTone.watch),
          if (score.tip != null)
            _ScoreNote(label: l10n.score.tip, text: score.tip!, tone: _NoteTone.tip),
          // Their own sentence, rewritten. Offered to borrow, never presented as
          // the answer they should have given.
          if (score.betterPhrasing != null) ...[
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: CoachStyle.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: CoachStyle.selectedBorderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.score.betterPhrasing,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: CoachStyle.textMuted,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    score.betterPhrasing!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: CoachStyle.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // The running skill number, only once there is history to average.
          if (skill != null && skill.score != null) ...[
            SizedBox(height: 11.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.score.skill(
                      score: skill.score!.toString(),
                      scenes: skill.scenes.toString(),
                    ),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: CoachStyle.selectedText,
                    ),
                  ),
                ),
                if (skill.trend != null && skill.trend! != 0)
                  Text(
                    skill.trend! > 0
                        ? l10n.score.trendUp(points: _oneDecimal(skill.trend!.abs()))
                        : l10n.score.trendDown(points: _oneDecimal(skill.trend!.abs())),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: skill.trend! > 0 ? CoachStyle.userBubble : CoachStyle.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "7.5", and "8" rather than "8.0" — a whole number with a decimal point
  /// reads as a measurement to two significant figures, which this is not.
  static String _oneDecimal(double value) {
    final rounded = (value * 10).round() / 10;

    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}

/// One rubric bar: what it checks, how it went, and why.
class _Criterion extends StatelessWidget {
  final CoachScoreCriterionEntity criterion;

  const _Criterion({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final fraction = (criterion.score / 10).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                criterion.label,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: CoachStyle.textBody,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              _ScoreCard._oneDecimal(criterion.score),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: CoachStyle.selectedText,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(99.r),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6.h,
            backgroundColor: CoachStyle.surface,
            valueColor: const AlwaysStoppedAnimation(CoachStyle.skin),
          ),
        ),
        if (criterion.note != null) ...[
          SizedBox(height: 4.h),
          Text(
            criterion.note!,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: CoachStyle.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

enum _NoteTone { good, watch, tip }

/// One labelled sentence on the card — the strength, the thing to sharpen, the tip.
class _ScoreNote extends StatelessWidget {
  final String label;
  final String text;
  final _NoteTone tone;

  const _ScoreNote({required this.label, required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    final mark = switch (tone) {
      _NoteTone.good => '●',
      _NoteTone.watch => '●',
      _NoteTone.tip => '●',
    };
    final color = switch (tone) {
      _NoteTone.good => CoachStyle.userBubble,
      _NoteTone.watch => CoachStyle.courseMeta,
      _NoteTone.tip => CoachStyle.skin,
    };

    return Padding(
      padding: EdgeInsets.only(top: 3.h, bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h, right: 7.w),
            child: Text(mark, style: TextStyle(fontSize: 8.sp, color: color)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: CoachStyle.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
