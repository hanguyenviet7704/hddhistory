part of '../../library.dart';

/// Library's four shelves, each a heading plus a horizontal strip of covers.
///
/// They were single summary ROWS ("Bài tôi tạo · 4 bài") until 2026-09-04: a
/// title, a count and a chevron, four of them stacked. The design replaced each
/// with the shelf itself, and the reason is the one that decides most feed
/// questions — a row tells you a shelf exists, a strip shows you what is on it,
/// and only one of those makes anyone open it. The chevron survives as the
/// "Xem tất cả" link beside each heading.
///
/// Every strip hides itself while empty rather than drawing an empty state:
/// four "nothing here yet" panels on one screen is a worse first run than a
/// short page.

/// Border shared by the bordered cards in these strips (design `#EDF0F5`).
const Color _kStripCardBorder = Color(0xFFEDF0F5);

/// Muted caption ink under a card title (design `#8891A3`).
const Color _kStripMutedInk = Color(0xFF8891A3);

/// A heading + its horizontal strip, with the strip bleeding to the screen edge.
///
/// The bleed is why the strip pays its own horizontal padding instead of
/// inheriting the page's: a list that stops 24 short of the edge reads as
/// clipped rather than as continuing.
class LibraryShelfStrip extends StatelessWidget {
  const LibraryShelfStrip({
    super.key,
    required this.title,
    required this.onSeeAll,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemGap,
    this.stripBottomPadding = 6,
  });

  final String title;
  final VoidCallback onSeeAll;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemGap;
  final double stripBottomPadding;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 24.h),
          child: _LibrarySectionHeader(
            title: title,
            trailingLabel: context.l10n.library.seeAllLink,
            onTrailingTap: onSeeAll,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, stripBottomPadding.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < itemCount; i++) ...[
                if (i > 0) SizedBox(width: itemGap.w),
                itemBuilder(context, i),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Nội dung của tôi" — the reader's own generated lessons
// ---------------------------------------------------------------------------

class LibraryMyCreationsStrip extends StatelessWidget {
  const LibraryMyCreationsStrip({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  /// Design `width:142px`, cover `height:96px`.
  static const double _cardWidth = 142;
  static const double _coverHeight = 96;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserLessonCubit, UserLessonState>(
      buildWhen: (previous, current) => previous.pageData != current.pageData,
      builder: (context, state) {
        final lessons = state.pageData.items;

        return LibraryShelfStrip(
          key: const Key('library-my-creations-strip'),
          title: context.l10n.learningImport.myLessonsTitle,
          onSeeAll: onSeeAll,
          itemCount: lessons.length,
          itemGap: 12,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return SizedBox(
              width: _cardWidth.w,
              child: Semantics(
                button: true,
                label: lesson.title,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptic.select();
                    LessonReaderRoute(lesson.id).push(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: studyThemeCardColor(context),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: _kStripCardBorder, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: _coverHeight.h,
                          width: double.infinity,
                          // `userLessonCoverArt` is what the shelf screen uses:
                          // the admin-pool cover the server dealt, or the bundled
                          // mock for a lesson made before that pool existed.
                          child: DCachedImage(url: userLessonCoverArt(lesson), fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(11.w, 10.h, 11.w, 12.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                lesson.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFont.mulish,
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: AppCustomColor.textPrimary,
                                ),
                              ),
                              6.verticalSpace,
                              AppText(
                                _statusLabel(context, lesson),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFont.mulish,
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _kStripMutedInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// The one line under the title: how long the lesson is, or that it is still
  /// being written.
  ///
  /// `isContentPartial` is the same signal the shelf screen reads — a lesson
  /// whose later keypoints are still being generated is openable but not
  /// finished, and saying "5 phút" about it would be a number that grows while
  /// you look at it.
  String _statusLabel(BuildContext context, UserLessonEntity lesson) {
    final l10n = context.l10n.learningImport;
    if (lesson.isContentPartial) return l10n.statusCreating;
    return l10n.minutesRead(minutes: lesson.estimatedMinutes);
  }
}

// ---------------------------------------------------------------------------
// "Khoá học đã lưu" — the courses the reader bookmarked
// ---------------------------------------------------------------------------

class LibrarySavedCoursesStrip extends StatelessWidget {
  const LibrarySavedCoursesStrip({super.key, required this.onSeeAll, required this.onOpenCourse});

  final VoidCallback onSeeAll;
  final void Function(CourseEntity course) onOpenCourse;

  /// Design `width:132px`, cover square.
  static const double _cardWidth = 132;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedCubit, SavedState>(
      buildWhen: (previous, current) => previous.coursesPageData != current.coursesPageData,
      builder: (context, state) {
        final courses = state.coursesPageData.items;

        return LibraryShelfStrip(
          key: const Key('library-saved-courses-strip'),
          title: context.l10n.library.savedRowTitle,
          onSeeAll: onSeeAll,
          itemCount: courses.length,
          itemGap: 14,
          itemBuilder: (context, index) {
            final course = courses[index];
            return SizedBox(
              width: _cardWidth.w,
              child: LibraryCoverCard(
                course: course,
                onTap: () => onOpenCourse(course),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// "Thẻ đã lưu" — the recap cards kept from the end of a keypoint
// ---------------------------------------------------------------------------

class LibrarySavedCardsStrip extends StatelessWidget {
  const LibrarySavedCardsStrip({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  /// Design `width:118px; aspect-ratio:3/4`.
  static const double _cardWidth = 118;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedCubit, SavedState>(
      buildWhen: (previous, current) => previous.cardsPageData != current.cardsPageData,
      builder: (context, state) {
        final cards = state.cards;

        return LibraryShelfStrip(
          key: const Key('library-saved-cards-strip'),
          title: context.l10n.library.savedCardsRowTitle,
          onSeeAll: onSeeAll,
          itemCount: cards.length,
          itemGap: 12,
          stripBottomPadding: 10,
          itemBuilder: (context, index) {
            final card = cards[index];
            return SizedBox(
              width: _cardWidth.w,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Semantics(
                  button: true,
                  label: card.displayTitle,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptic.select();
                      SavedCardDetailOverlay.show(context, card: card);
                    },
                    child: _SavedCardTile(card: card),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The quote-card thumbnail: an oversized opening mark, the line itself, a rule
/// and the course it came from.
class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({required this.card});

  final SavedCardEntity card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 34.h),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kStripCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -12.h,
            left: -6.w,
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 46.sp,
                fontWeight: FontWeight.w700,
                height: 1,
                color: const Color(0xFFF0EEFC),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                card.displayTitle,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                  color: AppCustomColor.textPrimary,
                ),
              ),
              8.verticalSpace,
              Container(
                width: 18.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFCBF2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              6.verticalSpace,
              AppText(
                card.courseTitle.text.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 7.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.07 * 7.5.sp,
                  color: AppCustomColor.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Sổ hành trình" — the weeks already wrapped up
// ---------------------------------------------------------------------------

class LibraryNotebookStrip extends StatelessWidget {
  const LibraryNotebookStrip({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  /// Design `width:104px`, cover `aspect-ratio:4/5`.
  static const double _cardWidth = 104;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekRecapCubit, WeekRecapState>(
      bloc: AppDI.injector.get<WeekRecapCubit>(),
      buildWhen: (previous, current) => previous.archive != current.archive,
      builder: (context, state) {
        final weeks = state.archive.items;
        final l10n = context.l10n.weekRecap;

        return LibraryShelfStrip(
          key: const Key('library-notebook-strip'),
          title: l10n.notebookRowTitle,
          onSeeAll: onSeeAll,
          itemCount: weeks.length,
          itemGap: 12,
          stripBottomPadding: 10,
          itemBuilder: (context, index) {
            final week = weeks[index];
            return SizedBox(
              width: _cardWidth.w,
              child: Semantics(
                button: true,
                label: l10n.weekLabel(number: week.weekNumber.toString().padLeft(2, '0')),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptic.select();
                    unawaited(AppDI.injector.get<WeekRecapCubit>().openRecapById(week.id));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: studyThemeCardColor(context),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: _kStripCardBorder, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: ColoredBox(
                            color: AppCustomColor.weekRecapPaper,
                            child: Image.asset(
                              weekRecapArtworkAsset(),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                l10n.weekLabel(number: week.weekNumber.toString().padLeft(2, '0')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFont.mulish,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppCustomColor.textPrimary,
                                ),
                              ),
                              2.verticalSpace,
                              AppText(
                                _range(week),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFont.mulish,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _kStripMutedInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// `12–18/8`. The end date is `weekEnd` minus a day: the stored bound is
  /// exclusive (the next Monday), and printing it would claim a day the week
  /// does not contain. Shorter than the archive screen's version — the card is
  /// 104 wide and the year is the same on all of them.
  String _range(WeekRecapSummaryEntity week) {
    final start = week.weekStart;
    final last = week.weekEnd.subtract(const Duration(days: 1));
    return '${start.day}–${last.day}/${last.month}';
  }
}

// ---------------------------------------------------------------------------
// The square cover card used by the saved-courses strip
// ---------------------------------------------------------------------------

/// A course as a square cover with its title and author under it — the same
/// shape Explore and Home's "Gợi ý cho bạn" use, so a course looks like itself
/// wherever it is shown.
///
/// Distinct from [LibraryCourseCard], which is the wide 322×98 progress row the
/// "Đang học" strip needs: a bookmarked course has no progress to draw, so the
/// cover is all there is to show.
class LibraryCoverCard extends StatelessWidget {
  const LibraryCoverCard({super.key, required this.course, required this.onTap});

  final CourseEntity course;
  final VoidCallback onTap;

  /// Two lines of title at 12.5/1.35, reserved whether or not the title needs
  /// them, so cards in a row line up along their author line.
  static const double _titleHeight = 34;

  @override
  Widget build(BuildContext context) {
    final author = course.author?.trim() ?? '';

    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverArt(url: course.image, seed: course.id, label: course.title.text),
                    if ((course.displayViewCount ?? 0) > 0)
                      Positioned(
                        right: 9.r,
                        bottom: 9.r,
                        child: CourseViewsChip(count: course.displayViewCount!),
                      ),
                  ],
                ),
              ),
            ),
            8.verticalSpace,
            SizedBox(
              height: _titleHeight.h,
              width: double.infinity,
              child: AppText(
                course.title.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                ),
              ),
            ),
            4.verticalSpace,
            if (author.isNotEmpty)
              CourseAuthorLine(
                author: author,
                color: studyThemeOnBg(context, kCourseMetaAuthorColor),
              ),
          ],
        ),
      ),
    );
  }
}
