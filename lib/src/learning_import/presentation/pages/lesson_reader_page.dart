part of '../../learning_import.dart';

/// Reads one generated lesson as ONE continuous scroll.
///
/// Not paged card-by-card like a catalogue keypoint: this content is prose the
/// user brought themselves, and the reading posture is an article, not a drill.
/// Section headings pin to the top as you pass them so it never stops being
/// clear which part you are in.
class LessonReaderPage extends StatefulWidget {
  const LessonReaderPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<LessonReaderPage> createState() => _LessonReaderPageState();
}

class _LessonReaderPageState extends State<LessonReaderPage> {
  final ScrollController _scrollController = ScrollController();

  /// Section keys, so the topmost visible one can be found on the way out.
  final List<GlobalKey> _sectionKeys = [];

  double _progress = 0;

  @override
  void initState() {
    super.initState();
    context.read<UserLessonCubit>().openLesson(widget.lessonId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveProgress();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;

    final next = (_scrollController.offset / max).clamp(0.0, 1.0);
    // Only repaint the progress bar on a visible change — this fires on every
    // scroll frame otherwise.
    if ((next - _progress).abs() > 0.005) setState(() => _progress = next);
  }

  /// Save the topmost visible section as the bookmark.
  ///
  /// A section index rather than a pixel offset: an offset is meaningless after
  /// a font-size change or a re-render, whereas "you were in part 4" survives
  /// both and is what the card's progress label reads from.
  void _saveProgress() {
    final cubit = context.read<UserLessonCubit>();
    final lesson = cubit.state.selected;
    if (lesson == null || _sectionKeys.isEmpty) return;

    var topIndex = 0;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final renderObject = _sectionKeys[i].currentContext?.findRenderObject();
      if (renderObject is! RenderBox) continue;

      final dy = renderObject.localToGlobal(Offset.zero).dy;
      if (dy <= 120) topIndex = i;
    }

    cubit.saveProgress(lessonId: lesson.id, sectionIndex: topIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: ThemedBackground(
        child: SafeBody(
          child: BlocBuilder<UserLessonCubit, UserLessonState>(
            builder: (context, state) {
              final lesson = state.selected;

              if (state.isLoading || lesson == null) {
                return const Center(child: CircularProgressIndicator());
              }

              _syncSectionKeys(lesson.sections.length);

              return Column(
                children: [
                  _ReaderHeader(title: lesson.title, progress: _progress),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (lesson.description.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                              child: AppText(
                                lesson.description,
                                maxLines: 6,
                                style: AppStyle.text14.copyWith(
                                  color: studyThemeOnBg(
                                    context,
                                    AppCustomColor.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        for (var i = 0; i < lesson.sections.length; i++)
                          _ReaderSection(
                            key: _sectionKeys[i],
                            section: lesson.sections[i],
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 40.h + MediaQuery.paddingOf(context).bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _syncSectionKeys(int length) {
    if (_sectionKeys.length == length) return;

    _sectionKeys
      ..clear()
      ..addAll(List.generate(length, (_) => GlobalKey()));
  }
}

/// Back button, title, and the thin progress line.
class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.title, required this.progress});

  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 20.w, 4.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20.w,
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                ),
              ),
              Expanded(
                child: AppText(
                  title,
                  maxLines: 1,
                  style: AppStyle.textBold16.copyWith(
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          minHeight: 2.h,
          backgroundColor: AppCustomColor.borderDefault,
          valueColor: const AlwaysStoppedAnimation(AppCustomColor.brandPrimary),
        ),
      ],
    );
  }
}

/// One section: a heading that sticks while its body scrolls under it.
class _ReaderSection extends StatelessWidget {
  const _ReaderSection({required this.section, super.key});

  final LessonSectionEntity section;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            title: section.title,
            background: studyThemeScaffoldColor(
              context,
              AppCustomColor.backgroundWhite,
            ),
            foreground: studyThemeOnBg(context, AppCustomColor.textPrimary),
            height: 48.h,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final block = section.blocks[index];
              final isHeading = block.type == LessonBlockTypeEntity.heading;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  isHeading ? 16.h : 0,
                  20.w,
                  12.h,
                ),
                child: AppText(
                  block.text,
                  // Prose: no truncation. The default maxLines on AppText is 10,
                  // which would silently clip most paragraphs here.
                  maxLines: 1000,
                  overflow: TextOverflow.visible,
                  style: isHeading
                      ? AppStyle.textBold16.copyWith(
                          color: studyThemeOnBg(
                            context,
                            AppCustomColor.textPrimary,
                          ),
                        )
                      : AppStyle.text16.copyWith(
                          height: 1.6,
                          color: studyThemeOnBg(
                            context,
                            AppCustomColor.textPrimary,
                          ),
                        ),
                ),
              );
            },
            childCount: section.blocks.length,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.title,
    required this.background,
    required this.foreground,
    required this.height,
  });

  final String title;
  final Color background;
  final Color foreground;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      width: double.infinity,
      // Opaque so body text does not show through the pinned heading. With a
      // custom study background the scaffold colour is transparent, so fall
      // back to a solid card colour instead.
      color: background == Colors.transparent
          ? studyThemeCardColor(context, opacity: 1)
          : background,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AppText(
        title,
        maxLines: 1,
        style: AppStyle.textBold16.copyWith(color: foreground),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      oldDelegate.title != title ||
      oldDelegate.background != background ||
      oldDelegate.foreground != foreground ||
      oldDelegate.height != height;
}
