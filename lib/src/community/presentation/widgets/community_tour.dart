part of '../../community.dart';

/// The first-run walk through the forum (design `HDDhistory Confession.html`,
/// "Tour lần đầu (bắt buộc)", screens S-T1…S-T6).
///
/// Six beats: a welcome card, then four things pointed at by name — the two
/// feed tabs, the rooms tab, the round-table bubble and the compose button.
/// Shown once per PERSON, not once per install: the flag lives on the user
/// (`memberStatus.tourSeen`) and the last step is what stamps it.
///
/// Deliberately has no skip. The design marks the tour `bắt buộc`, and it is
/// six taps on the one screen whose whole subject is what the tabs mean — a
/// reader who dismisses it is the reader who then cannot find the rooms. Leaving
/// the tab mid-way is still an escape: nothing is stamped until the last step,
/// so the tour simply starts again next time.
enum CommunityTourStep {
  /// S-T1 — the centred welcome card. Points at nothing.
  welcome,

  /// S-T2 — the "Tất cả" chip.
  tabAll,

  /// S-T3 — the "Đang theo dõi" chip.
  tabFollowing,

  /// S-T4 — the "Phòng" chip.
  tabRooms,

  /// S-T5 — the round-table bubble, bottom right.
  chatBubble,

  /// S-T6 — the compose button, top right.
  compose;

  /// Which numbered beat this is, for "N/6". The welcome card is 1.
  int get number => index + 1;

  static const int count = 6;

  /// The tab the forum must be showing BEHIND this step, or null to leave it.
  ///
  /// The tour narrates the tabs, so it switches them as it goes — pointing at
  /// "Đang theo dõi" while the feed underneath is still "Tất cả" would be
  /// pointing at a word rather than at a thing.
  int? get underlyingTabIndex => switch (this) {
    CommunityTourStep.tabFollowing => 1,
    CommunityTourStep.tabRooms => 2,
    CommunityTourStep.welcome || CommunityTourStep.tabAll || CommunityTourStep.chatBubble || CommunityTourStep.compose => 0,
  };

  CommunityTourStep? get next => number < count ? CommunityTourStep.values[index + 1] : null;
}

/// Where each pointing step aims. Filled by the page, read by the overlay.
///
/// Keys rather than hard-coded rectangles: the design positions its spotlights
/// with absolute pixels against one 390pt mock, and the real header moves with
/// the text size, the locale and the notch.
class CommunityTourAnchors {
  final GlobalKey tabAll = GlobalKey();
  final GlobalKey tabFollowing = GlobalKey();
  final GlobalKey tabRooms = GlobalKey();
  final GlobalKey chatBubble = GlobalKey();
  final GlobalKey compose = GlobalKey();

  GlobalKey? keyFor(CommunityTourStep step) => switch (step) {
    CommunityTourStep.welcome => null,
    CommunityTourStep.tabAll => tabAll,
    CommunityTourStep.tabFollowing => tabFollowing,
    CommunityTourStep.tabRooms => tabRooms,
    CommunityTourStep.chatBubble => chatBubble,
    CommunityTourStep.compose => compose,
  };
}

/// The dimmed sheet, the cut-out and the card. Sits above everything on the hub.
class CommunityTour extends StatelessWidget {
  const CommunityTour({
    super.key,
    required this.step,
    required this.anchors,
    required this.onNext,
  });

  final CommunityTourStep step;
  final CommunityTourAnchors anchors;

  /// Advances, or finishes on the last step.
  final VoidCallback onNext;

  static const Color _scrim = Color(0xC316130B);
  static const double _cardWidth = 262;
  static const double _gap = 12;

  ({String title, String body, String cta}) _copy(BuildContext context) {
    final l10n = context.l10n.community;

    return switch (step) {
      CommunityTourStep.welcome => (title: l10n.tourWelcomeTitle, body: l10n.tourWelcomeBody, cta: l10n.tourWelcomeCta),
      CommunityTourStep.tabAll => (title: l10n.tourAllTitle, body: l10n.tourAllBody, cta: l10n.tourNext),
      CommunityTourStep.tabFollowing => (title: l10n.tourFollowingTitle, body: l10n.tourFollowingBody, cta: l10n.tourNext),
      CommunityTourStep.tabRooms => (title: l10n.tourRoomsTitle, body: l10n.tourRoomsBody, cta: l10n.tourNext),
      CommunityTourStep.chatBubble => (title: l10n.tourChatTitle, body: l10n.tourChatBody, cta: l10n.tourNext),
      CommunityTourStep.compose => (title: l10n.tourComposeTitle, body: l10n.tourComposeBody, cta: l10n.tourComposeCta),
    };
  }

  /// The target's rectangle in the overlay's own coordinates, or null when it
  /// cannot be measured — a tab that is not laid out yet, or the welcome step.
  Rect? _targetRect(BuildContext context) {
    final key = anchors.keyFor(step);
    final targetBox = key?.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || overlayBox == null || !targetBox.hasSize) return null;

    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    return topLeft & targetBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final target = _targetRect(context);

        return Stack(
          children: [
            // The dim sheet WITH a hole punched in it, and the ring around the
            // hole. One painter rather than the design's `box-shadow: 0 0 0
            // 9999px`: CSS clips a box-shadow to outside the border box, and
            // Flutter does not — a transparent box over a huge spread shadow
            // leaves the scrim painted straight across the thing it is meant to
            // be revealing, which is exactly how it first shipped (the
            // highlighted chip came out darker than the rest of the screen).
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Swallows every tap that is not the button: the tour is the
                // only thing on screen until it is done.
                onTap: () {},
                child: CustomPaint(
                  painter: _SpotlightPainter(hole: target),
                  size: Size.infinite,
                ),
              ),
            ),
            if (target == null)
              _WelcomeCard(step: step, copy: copy, onNext: onNext)
            else
              _TipCard(
                step: step,
                copy: copy,
                target: target,
                bounds: constraints.biggest,
                onNext: onNext,
              ),
          ],
        );
      },
    );
  }
}

/// The dim sheet, minus the thing being pointed at.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole});

  /// The target in overlay coordinates, or null for an undimmed-nothing sheet.
  final Rect? hole;

  static const double _padding = 4;
  static const double _ring = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = CommunityTour._scrim;
    final screen = Offset.zero & size;
    final target = hole;

    if (target == null) {
      canvas.drawRect(screen, scrim);

      return;
    }

    final inflated = target.inflate(_padding);
    final rrect = RRect.fromRectAndRadius(
      inflated,
      Radius.circular(inflated.height / 2),
    );

    // `ui.Path`, not `Path`: this library also imports Retrofit, whose `@Path`
    // annotation owns that name here.
    canvas.drawPath(
      ui.Path.combine(
        ui.PathOperation.difference,
        ui.Path()..addRect(screen),
        ui.Path()..addRRect(rrect),
      ),
      scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ring
        ..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => oldDelegate.hole != hole;
}

/// S-T1 — the centred card. No arrow, nothing highlighted: the forum has not
/// been introduced yet, so there is nothing to point at.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.step, required this.copy, required this.onNext});

  final CommunityTourStep step;
  final ({String title, String body, String cta}) copy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 34.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 60, offset: const Offset(0, 26)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.brandPrimary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.forum_rounded, size: 26.sp, color: AppCustomColor.brandPrimary),
              ),
              SizedBox(height: 16.h),
              AppText(
                copy.title,
                textAlign: TextAlign.center,
                maxLines: 100,
                style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
              ),
              SizedBox(height: 9.h),
              AppText(
                copy.body,
                textAlign: TextAlign.center,
                maxLines: 100,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.6),
              ),
              SizedBox(height: 18.h),
              _TourDots(step: step),
              SizedBox(height: 14.h),
              _TourButton(label: copy.cta, height: 46, onTap: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

/// S-T2…S-T6 — the card beside the thing being pointed at, with a caret.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.copy,
    required this.target,
    required this.bounds,
    required this.onNext,
  });

  final CommunityTourStep step;
  final ({String title, String body, String cta}) copy;
  final Rect target;
  final Size bounds;
  final VoidCallback onNext;

  /// True when the card sits BELOW the target (caret pointing up).
  ///
  /// Decided by where the target actually is rather than per step: the header
  /// chips are near the top and the bubble is near the bottom, and a card that
  /// runs off the screen is worse than one on the "wrong" side.
  bool get _below => target.center.dy < bounds.height / 2;

  @override
  Widget build(BuildContext context) {
    final width = CommunityTour._cardWidth.w;
    // Kept inside the screen, and pulled toward the target so the caret has
    // somewhere honest to sit.
    final rawLeft = target.center.dx - width / 2;
    final left = rawLeft.clamp(16.w, math.max(16.w, bounds.width - width - 16.w)).toDouble();
    final caretLeft = (target.center.dx - left - 7.w).clamp(18.w, width - 32.w).toDouble();

    final card = Container(
      width: width,
      padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: const Color(0x6616130B), blurRadius: 40, offset: const Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '${step.number}/${CommunityTourStep.count}',
                style: AppStyle.textBold10.copyWith(color: const Color(0xFFBF921D), letterSpacing: 0.8),
              ),
              _TourDots(step: step, compact: true),
            ],
          ),
          SizedBox(height: 7.h),
          AppText(
            copy.title,
            maxLines: 100,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
          SizedBox(height: 5.h),
          AppText(
            copy.body,
            maxLines: 100,
            style: AppStyle.text12.copyWith(color: AppCustomColor.textSecondary, height: 1.55),
          ),
          SizedBox(height: 14.h),
          _TourButton(label: copy.cta, height: 38, onTap: onNext),
        ],
      ),
    );

    // The caret is a rotated square tucked half under the card, exactly as the
    // design draws it.
    final caret = Positioned(
      left: caretLeft,
      top: _below ? 0 : null,
      bottom: _below ? null : 0,
      child: Transform.translate(
        offset: Offset(0, _below ? -6.h : 6.h),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: left,
      top: _below ? target.bottom + CommunityTour._gap.h : null,
      bottom: _below ? null : bounds.height - target.top + CommunityTour._gap.h,
      child: Stack(clipBehavior: Clip.none, children: [card, caret]),
    );
  }
}

/// The progress dots. Six of them, the current one wide.
class _TourDots extends StatelessWidget {
  const _TourDots({required this.step, this.compact = false});

  final CommunityTourStep step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = (compact ? 5 : 6).w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= CommunityTourStep.count; i++) ...[
          if (i > 1) SizedBox(width: 4.w),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: i == step.number ? size * 3 : size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size),
              color: i == step.number
                  ? AppCustomColor.brandPrimary
                  : AppCustomColor.brandPrimary.withValues(alpha: 0.22),
            ),
          ),
        ],
      ],
    );
  }
}

class _TourButton extends StatelessWidget {
  const _TourButton({required this.label, required this.height, required this.onTap});

  final String label;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AppText(
          label,
          style: AppStyle.textBold14.copyWith(color: AppCustomColor.textWhite),
        ),
      ),
    );
  }
}
