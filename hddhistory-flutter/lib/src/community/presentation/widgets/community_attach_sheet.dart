part of '../../community.dart';

/// "Đính kèm từ thư viện" (design `S-06`).
///
/// Both tabs come from the reader's OWN library rather than a search over the
/// catalogue: what a post attaches is something the writer has actually done —
/// a course they are studying, a card they kept — and a picker over everything
/// would invite attaching things they have never opened.
void showCommunityAttachSheet(
  BuildContext context, {
  required void Function(CourseEntity course) onPickCourse,
  required void Function(SavedCardEntity card) onPickCard,
}) {
  showDModalBottomSheet(
    contentPadding: EdgeInsets.zero,
    // The height is pinned HERE, not via initialChildSize/maxChildSize: the
    // helper only feeds those to its own DraggableScrollableSheet on the
    // `body` path and ignores them for a `bodyWidget` — and this sheet's
    // Expanded column then grew to the full screen, where the title sat under
    // the clock (showModalBottomSheet strips the top MediaQuery padding, so
    // no SafeArea inside can save it). 82% leaves the status bar its strip.
    bodyWidget: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: _CommunityAttachSheet(
        onPickCourse: onPickCourse,
        onPickCard: onPickCard,
      ),
    ),
  );
}

enum _AttachTab { courses, cards }

class _CommunityAttachSheet extends StatefulWidget {
  const _CommunityAttachSheet({
    required this.onPickCourse,
    required this.onPickCard,
  });

  final void Function(CourseEntity course) onPickCourse;
  final void Function(SavedCardEntity card) onPickCard;

  @override
  State<_CommunityAttachSheet> createState() => _CommunityAttachSheetState();
}

class _CommunityAttachSheetState extends State<_CommunityAttachSheet> {
  static const int _pageSize = 20;

  _AttachTab _tab = _AttachTab.courses;
  List<CourseEntity> _courses = [];
  List<SavedCardEntity> _cards = [];
  bool _isLoadingCourses = true;
  bool _isLoadingCards = false;
  bool _hasLoadedCards = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    // In-progress first: the design's rows all carry a progress bar, and a
    // course at 0% has nothing to say in one.
    final result = await AppDI.injector
        .get<GetSavedCoursesUseCase>()(
          page: 1,
          take: _pageSize,
          filter: SavedCourseFilter.inProgress,
        )
        .run();
    if (!mounted) return;

    result.fold((_) => setState(() => _isLoadingCourses = false), (page) {
      setState(() {
        _courses = page.items;
        _isLoadingCourses = false;
      });
    });
  }

  /// Loaded on first switch, not upfront: most posts attach a course, and the
  /// card list is a second request the reader may never ask for.
  Future<void> _loadCards() async {
    if (_hasLoadedCards) return;

    setState(() {
      _hasLoadedCards = true;
      _isLoadingCards = true;
    });

    final result = await AppDI.injector
        .get<GetSavedCardsUseCase>()(page: 1, take: _pageSize)
        .run();
    if (!mounted) return;

    result.fold((_) => setState(() => _isLoadingCards = false), (page) {
      setState(() {
        _cards = page.items;
        _isLoadingCards = false;
      });
    });
  }

  void _selectTab(_AttachTab tab) {
    setState(() => _tab = tab);
    if (tab == _AttachTab.cards) unawaited(_loadCards());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A tall sheet without a grabber reads as a page with its top cut
          // off; the handle names it a sheet and invites the drag-to-dismiss
          // that is already enabled.
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppCustomColor.communityPlaceholder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 12.h),
            child: AppText(
              l10n.attachSheetTitle,
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 14.h),
            child: Row(
              children: [
                _TabChip(
                  label: l10n.attachTabCourses,
                  isActive: _tab == _AttachTab.courses,
                  onTap: () => _selectTab(_AttachTab.courses),
                ),
                SizedBox(width: 8.w),
                _TabChip(
                  label: l10n.attachTabCards,
                  isActive: _tab == _AttachTab.cards,
                  onTap: () => _selectTab(_AttachTab.cards),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == _AttachTab.courses
                ? _CourseList(
                    courses: _courses,
                    isLoading: _isLoadingCourses,
                    onPick: (course) {
                      Navigator.of(context).maybePop();
                      widget.onPickCourse(course);
                    },
                  )
                : _CardGrid(
                    cards: _cards,
                    isLoading: _isLoadingCards,
                    onPick: (card) {
                      Navigator.of(context).maybePop();
                      widget.onPickCard(card);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.courses,
    required this.isLoading,
    required this.onPick,
  });

  final List<CourseEntity> courses;
  final bool isLoading;
  final void Function(CourseEntity course) onPick;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (courses.isEmpty) {
      return _AttachEmpty(text: context.l10n.community.attachEmptyCourses);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
      itemCount: courses.length,
      separatorBuilder: (_, _) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        final course = courses[index];

        return GestureDetector(
          onTap: () => onPick(course),
          child: Container(
            height: 98.h,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppCustomColor.borderDefault,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(19.r),
                    bottomLeft: Radius.circular(19.r),
                  ),
                  child: DCachedImage(
                    url: course.image,
                    width: 98.w,
                    height: 98.h,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          course.title.text,
                          style: AppStyle.textBold14.copyWith(
                            color: AppCustomColor.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                        ),
                        if (course.author?.isNotEmpty == true) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 13.sp,
                                color: AppCustomColor.textSecondary,
                              ),
                              SizedBox(width: 5.w),
                              Expanded(
                                child: AppText(
                                  course.author!,
                                  style: AppStyle.text12.copyWith(
                                    color: AppCustomColor.textSecondary,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: course.completionPercentage / 100,
                            minHeight: 6.h,
                            backgroundColor: AppCustomColor.borderDefault,
                            valueColor: const AlwaysStoppedAnimation(
                              AppCustomColor.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.isLoading,
    required this.onPick,
  });

  final List<SavedCardEntity> cards;
  final bool isLoading;
  final void Function(SavedCardEntity card) onPick;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (cards.isEmpty) {
      return _AttachEmpty(text: context.l10n.community.attachEmptyCards);
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 3 / 4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];

        return GestureDetector(
          onTap: () => onPick(card),
          child: Container(
            padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 16.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  card.displayTitle,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.textPrimary,
                    height: 1.28,
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 9.h),
                Container(
                  width: 22.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary200,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 7.h),
                AppText(
                  card.courseTitle.text.toUpperCase(),
                  style: AppStyle.textBold10.copyWith(
                    color: AppCustomColor.streakTextMuted,
                    letterSpacing: 0.7,
                    height: 1.45,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachEmpty extends StatelessWidget {
  const _AttachEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: AppText(
          text,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.communityMuted,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
