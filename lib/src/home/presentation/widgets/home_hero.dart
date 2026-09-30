part of '../../home.dart';

/// How far the "Today's new course" card is lifted INTO the purple header.
///
/// From the app's own design (`_MeUp App`, pin `app:explore`), which is the
/// one the Home screen is drawn against now: the card carries `margin:-64px`.
/// The older standalone Home mock said -76 against a taller header — following
/// it left the card sitting deeper in the purple than the screen it belongs to.
const double _kHeroCardOverlap = 64;

/// Half the card's horizontal margin: the design's `width: calc(100% - 52px)`.
///
/// It used to be 8, from a mock that widened the card to `calc(100% - 16px)`.
/// At that width the card ran almost edge to edge and its artwork — whose
/// height is fixed — stretched to a ratio the design never draws, which is
/// what read as "tràn" on the simulator (owner, 2026-09-05).
const double _kHeroCardInset = 26;

/// Home's header: one purple panel carrying the greeting, the premium chip and
/// the settings gear — with the new-course card lifted out of its bottom edge.
///
/// The header is deliberately spare now. The streak chip and the avatar are
/// gone (design note 2026-09-04): the streak has a full card of its own further
/// down the page, and the avatar's job — reaching the account — is the gear's,
/// which opens one merged Settings screen instead of two. The quote left too,
/// and sits under the card rather than inside the purple (see [HomeQuote]).
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

/// The header's purple.
///
/// The design builds it from ONE base colour, `#8B84F2`, and lifts a second
/// stop 13% toward white for the gradient (`homeHdrBg` in the app's design
/// source) — so `#9A94F4 → #8B84F2`. The code carried the brand purple
/// `#6C63FF → #554FF0` instead, which is a whole step darker and more
/// saturated than the screen it is drawn on (owner, 2026-09-05: "chỗ xin chào
/// màu chưa giống design").
///
/// Flattened to horizontal so the panel and the foot below it can share it
/// without a seam — the design's 100deg tilt would show the join.
const LinearGradient _kHeroGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFFF1CE75), Color(0xFFEBBC46)],
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
      // The design leaves 14 under the greeting plus 78 of header padding = 92,
      // of which the last 76 is the foot the card sits on — so the panel itself
      // stops 16 short.
      // The design's 62 top is measured from y=0 over a 54-tall status bar, i.e. 8
      // of clear space under it; 12 keeps that tight look without crowding a
      // Dynamic Island.
      padding: EdgeInsets.fromLTRB(20.w, statusBar + 12.h, 20.w, roundedBottom ? 24.h : 16.h),
      decoration: BoxDecoration(
        gradient: _kHeroGradient,
        borderRadius: roundedBottom ? const BorderRadius.vertical(bottom: Radius.circular(30)) : null,
      ),
      child: const _HeroGreetingRow(),
    );
  }
}

/// Greeting + premium chip + settings gear, all on the purple.
class _HeroGreetingRow extends StatelessWidget {
  const _HeroGreetingRow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, ({String name, bool isPremium})>(
      selector: (state) => (name: state.user.name, isPremium: state.user.isPremium),
      builder: (context, profile) {
        final firstName = profile.name.trim().split(' ').first;
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
            // Premium crown. Hidden once they subscribe — the same rule the
            // Profile page's `_PremiumBanner` follows — so a paying reader is
            // never sold to.
            if (!profile.isPremium) ...[
              const HomePremiumChip(),
              7.horizontalSpace,
            ],
            const _HeroSettingsButton(),
          ],
        );
      },
    );
  }
}

/// The 30px settings gear on the purple header.
///
/// Replaces the streak chip AND the avatar that used to share this corner
/// (design note 2026-09-04). Both went to the same place, and the page below
/// now carries the streak itself, so one button to one merged Settings screen
/// says the same thing with a third of the chrome.
class _HeroSettingsButton extends StatelessWidget {
  const _HeroSettingsButton();

  /// Sets the branch index AND the route name. Entering an already-built branch
  /// through a raw `.go()` fires no didPush, so PageCubit's mirror — which the
  /// floating nav reads to decide which tab is lit — would otherwise stay on
  /// Home (see the comment on `PageCubit.onTapTab`).
  void _openSettings(BuildContext context) {
    AppHaptic.select();
    final page = context.read<PageCubit>();
    page.setCurrentIndex(2); // Setting/Profile branch
    ProfileRoute().go(context);
    page.setCurrentRouteName(RouteNamed.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.setting.settingTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSettings(context),
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Near-white rather than pure white (design `rgba(255,255,255,.92)`)
            // so the purple reads faintly through and the button sits ON the
            // header instead of punching a hole in it.
            color: AppCustomColor.textWhite.withValues(alpha: 0.92),
            boxShadow: [
              BoxShadow(color: const Color(0x2E252525), blurRadius: 10.r, offset: Offset(0, 4.h)),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(Icons.settings_outlined, size: 18.r, color: AppCustomColor.brandPrimary),
        ),
      ),
    );
  }
}

/// The day's quote — under the new-course card now, not inside the purple.
///
/// It changed voice with its position: on the header it was white, bold and
/// loud enough to compete with the greeting; on the page it is small, grey and
/// centred — a caption between the card above it and the banners below.
class HomeQuote extends StatelessWidget {
  const HomeQuote({super.key});

  /// Design `#8792A6`, which is a touch darker than the meta grey so the
  /// italic still reads at 11.5.
  static const Color _ink = Color(0xFF8792A6);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, QuoteEntity?>(
      selector: (state) => state.quote,
      builder: (context, quote) {
        final text = quote?.content.text ?? '';
        // Collapses with its own bottom gap: no quote today must not leave a
        // hole between the card and the banner strip.
        if (text.isEmpty) return const SizedBox.shrink();

        // The design's grey was picked against the stock lavender page. The
        // quote is drawn straight onto the study background, so over a photo it
        // has to lift the same way every other bare-on-background line on Home
        // does — at #8792A6 on a dark wallpaper it was barely legible
        // (simulator, 2026-09-04).
        final ink = studyThemeOnBg(context, _ink);

        // The marks are set bigger than the sentence and sit on the same line
        // as it (design: `line-height:0; vertical-align:-2px`).
        final markStyle = TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          height: 1,
          color: ink,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(32.w, 0, 32.w, 22.h),
          // Full width, or `textAlign: center` centres nothing: Home's column
          // is `crossAxisAlignment: start`, so without this the block shrinks
          // to the width of the sentence and gets pinned to the left edge —
          // the text was centred inside a box that hugged it (owner,
          // 2026-09-05: "quote căn giữa màn hình").
          child: SizedBox(
            width: double.infinity,
            child: Semantics(
              label: context.l10n.home.homeQuoteLabel,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '“', style: markStyle),
                    TextSpan(text: text),
                    TextSpan(text: '”', style: markStyle),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: ink,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
