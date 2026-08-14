part of '../../home.dart';

/// How far the "Today's new course" card is lifted INTO the purple header
/// (design `2 · Home`: the card carries `margin-top:-64px` against a header
/// whose `padding-bottom` is 78).
const double _kHeroCardOverlap = 64;

/// The card is inset further than the page's own 20 (design: the card is
/// `calc(100% - 52px)` wide), which is what makes it read as sitting ON the
/// header rather than as another full-width section.
const double _kHeroCardInset = 26;

/// Home's header: one purple panel carrying the greeting, the streak chip, the
/// change-background button and the day's quote — with the new-course card
/// lifted out of its bottom edge.
///
/// Replaces the previous flat greeting + lavender quote card. The quote is no
/// longer a card of its own: on the purple it is the header's own voice, which
/// is why it lost the eyebrow and the medallion the standalone card needed to
/// separate itself from the page.
///
/// The panel deliberately runs BEHIND the status bar (design: the header starts
/// at y=0 with a 62px top padding, and the status bar is drawn over it), so Home
/// opts out of the top safe area and pays that inset here instead.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.hasUpdateHeader});

  /// The optional-update banner already consumed the status-bar inset above us,
  /// so the panel must not pay it twice.
  final bool hasUpdateHeader;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<SuggestedCourseEntity>>(
      selector: (state) => state.suggestedCourses,
      builder: (context, courses) {
        final course = _pickTodayCourse(courses);
        // No course to feature: the panel closes with its own rounded edge and
        // nothing is lifted out of it.
        if (course == null) return _HeroPanel(hasUpdateHeader: hasUpdateHeader, roundedBottom: true);

        // The gradient is drawn as TWO boxes — the panel that holds the text,
        // then a 64-tall foot the card sits on — because that is the only
        // measure-free way to get the design's overlap: a Stack sized by the
        // card can position the foot at its top, where a single box would need
        // the panel's height to know where to put the card. Everything after the
        // hero then follows in ordinary flow, so its 20 gap is exactly the 20 the
        // design asks for (an earlier `Transform` on the card alone left a 64
        // hole under it instead).
        //
        // The two boxes are seamless only because the gradient is horizontal —
        // every row is identical, so the split cannot show. The design's 100deg
        // tilt is dropped for exactly that reason.
        return Column(
          children: [
            _HeroPanel(hasUpdateHeader: hasUpdateHeader, roundedBottom: false),
            Stack(
              children: [
                // The foot: gradient behind the card's top, carrying the panel's
                // rounded bottom edge. Visible either side of the card, which is
                // inset further than the page (see [_kHeroCardInset]).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _kHeroCardOverlap.h,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _kHeroGradient,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                  ),
                ),
                // Sizes the Stack, and covers the foot's middle: the card's own
                // top 64 IS the overlap.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _kHeroCardInset.w),
                  child: _NewTodayCard(course: course),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The featured course: the newest by `createdAt`, falling back to a
/// day-stable rotation through the list when none of them carry a date.
SuggestedCourseEntity? _pickTodayCourse(List<SuggestedCourseEntity> courses) {
  if (courses.isEmpty) return null;

  SuggestedCourseEntity? newest;
  for (final course in courses) {
    final createdAt = course.createdAt;
    if (createdAt == null) continue;
    if (newest == null || createdAt.isAfter(newest.createdAt!)) newest = course;
  }
  if (newest != null) return newest;

  final now = DateTime.now();
  final dayIndex = DateTime(now.year, now.month, now.day).difference(DateTime(2020)).inDays % courses.length;
  return courses[dayIndex];
}

/// Design `linear-gradient(100deg,#6C63FF,#554FF0)`, flattened to horizontal so
/// the panel and the foot below it can share it without a seam.
const LinearGradient _kHeroGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF6C63FF), Color(0xFF554FF0)],
);

/// The purple panel itself.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.hasUpdateHeader, required this.roundedBottom});

  final bool hasUpdateHeader;

  /// True only when nothing is lifted out of the panel — otherwise the foot
  /// under it carries the rounded edge (see [HomeHero]).
  final bool roundedBottom;

  @override
  Widget build(BuildContext context) {
    final statusBar = hasUpdateHeader ? 0.0 : MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      // 78 below the quote in the design, of which the last 64 is the foot the
      // card sits on — so the panel itself stops 14 short.
      // The design's 62 top is measured from y=0 over a 54-tall status bar, i.e. 8
      // of clear space under it; 12 keeps that tight look without crowding a
      // Dynamic Island.
      padding: EdgeInsets.fromLTRB(20.w, statusBar + 12.h, 20.w, roundedBottom ? 24.h : 14.h),
      decoration: BoxDecoration(
        gradient: _kHeroGradient,
        borderRadius: roundedBottom ? const BorderRadius.vertical(bottom: Radius.circular(30)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroGreetingRow(),
          16.verticalSpace,
          const _HeroQuote(),
        ],
      ),
    );
  }
}

/// Greeting + streak chip + change-background button, all on the purple.
class _HeroGreetingRow extends StatelessWidget {
  const _HeroGreetingRow();

  /// The streak chip switches to the Profile tab (user call, 2026-08-05).
  ///
  /// It used to push the streak-detail popup. Profile's own streak card is now
  /// where the week is read, so the chip hands over to that page instead of
  /// stacking a second streak surface on top of Home. No re-entrancy guard is
  /// needed either: switching a branch is idempotent, where the old `push`
  /// would stack a duplicate route on a double tap.
  ///
  /// Sets the branch index AND the route name. Entering an already-built branch
  /// through a raw `.go()` fires no didPush, so PageCubit's mirror — which the
  /// floating nav reads to decide which tab is lit — would otherwise stay on
  /// Home (see the comment on `PageCubit.onTapTab`).
  void _openProfile(BuildContext context, int currentStreak) {
    AppService.instance.appTrackingService.trackHomeStreakChipClick(currentStreak: currentStreak);

    final page = context.read<PageCubit>();
    page.setCurrentIndex(2); // Setting/Profile branch
    ProfileRoute().go(context);
    page.setCurrentRouteName(RouteNamed.profile);
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = context.select((LearningStreakCubit cubit) => cubit.state.selectedItem.currentStreak);

    return BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (state) => state.user.name,
      builder: (context, username) {
        final firstName = username.trim().split(' ').first;
        final prefix = context.l10n.home.homeGreetingPrefix;
        final greeting = firstName.isEmpty ? '$prefix!' : '$prefix, $firstName!';

        return Row(
          children: [
            Expanded(
              // One line, no secondary question beneath it: the design promotes
              // the greeting itself to the page title.
              child: AppText(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                  color: AppCustomColor.textWhite,
                ),
              ),
            ),
            12.horizontalSpace,
            StreakHomeChip(
              currentStreak: currentStreak,
              onTap: () => _openProfile(context, currentStreak),
            ),
            12.horizontalSpace,
            // The avatar replaces the change-background button (design updated
            // 2026-08-14): theme now lives in Settings, and this slot is the
            // face of the account — tapping it opens Profile, same as the
            // streak chip.
            _HeroAvatarButton(onTap: () => _openProfile(context, currentStreak)),
          ],
        );
      },
    );
  }
}

/// The day's quote, in the header's own voice: italic, white, wrapped in
/// oversized quote marks instead of a card.
class _HeroQuote extends StatelessWidget {
  const _HeroQuote();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, QuoteEntity?>(
      selector: (state) => state.quote,
      builder: (context, quote) {
        final text = quote?.content.text ?? '';
        if (text.isEmpty) return const SizedBox.shrink();

        // The marks are set bigger and fainter than the sentence and sit on the
        // same line as it (design: `line-height:0; vertical-align:-4px`).
        final markStyle = TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          height: 1,
          color: AppCustomColor.textWhite.withValues(alpha: 0.6),
        );

        return Semantics(
          label: context.l10n.home.homeQuoteLabel,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '“', style: markStyle),
                TextSpan(text: text),
                TextSpan(text: '”', style: markStyle),
              ],
            ),
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: AppCustomColor.textWhite.withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}


/// The 30px account avatar on the purple header (design: `acctColor` disc with
/// the initial, or the photo, inside a near-white ring). Opens Profile.
class _HeroAvatarButton extends StatelessWidget {
  const _HeroAvatarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = context.select((ProfileCubit cubit) => cubit.state.user);
    final avatarUrl = user.avatar.trim();
    String ref = user.name.trim();
    if (ref.isEmpty) ref = user.email.trim();
    final initial = ref.isEmpty ? '?' : String.fromCharCode(ref.runes.first).toUpperCase();

    return Semantics(
      button: true,
      label: context.l10n.setting.settingProfileLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppCustomColor.brandPrimary700,
            border: Border.all(color: AppCustomColor.textWhite.withValues(alpha: 0.95), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0x2E252525), blurRadius: 10.r, offset: Offset(0, 4.h)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: avatarUrl.isNotEmpty
              // ClipOval on the image itself, not just the Container's
              // decoration clip: at this small size the decoration clip left
              // the photo's corners peeking out past the ring (4 white wedges,
              // seen on-device 2026-08-14) — the same pattern
              // _SettingProfileAvatar uses, which renders clean.
              ? ClipOval(
                  child: CacheNetworkGraphic(url: avatarUrl, width: 30.r, height: 30.r, fit: BoxFit.cover),
                )
              : Text(
                  initial,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppCustomColor.textWhite,
                  ),
                ),
        ),
      ),
    );
  }
}
