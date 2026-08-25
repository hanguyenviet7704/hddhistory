part of '../../community.dart';

/// Author avatar: the photo when there is one, initials otherwise.
///
/// The tint is derived from the name so the same person keeps the same colour
/// across the whole forum — a stable identity cue where there is no photo,
/// which is most of the time.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.author, this.size = 38});

  final CommunityAuthorEntity author;
  final double size;

  static const List<Color> _tints = [
    Color(0xFFE6F1F0),
    Color(0xFFFBE4EC),
    Color(0xFFF0EDE4),
    Color(0xFFFBE4DC),
    Color(0xFFE7EEFC),
  ];

  static const List<Color> _inks = [
    Color(0xFF2F7370),
    Color(0xFFC2417B),
    Color(0xFF8A7434),
    Color(0xFFC2632F),
    Color(0xFF3A63B8),
  ];

  /// Up to two initials, so a two-word name reads as "KH" like the design.
  String get _initials {
    final parts = author.name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '';

    return parts.take(2).map((part) => part.characters.first.toUpperCase()).join();
  }

  int get _slot {
    if (author.name.isEmpty) return 0;

    return author.name.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % _tints.length;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = author.avatar;
    final diameter = size.w;

    if (avatar != null && avatar.isNotEmpty) {
      // ClipOval on the image itself, not a circular Container around it: a
      // clipped decoration leaks the image's corners at small sizes.
      return ClipOval(
        child: DCachedImage(url: avatar, width: diameter, height: diameter, fit: BoxFit.cover),
      );
    }

    // An anonymous post carries no name and no id, so there is nothing to
    // derive a tint or initials FROM — a glyph on neutral grey, the same for
    // every anonymous post, which is the point: two of them must not look like
    // they came from the same person or from different ones.
    if (author.isAnonymous) {
      return Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppCustomColor.backgroundGray,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: diameter * 0.55,
          color: AppCustomColor.communityMuted,
        ),
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: author.isOfficial ? AppCustomColor.brandPrimary50 : _tints[_slot],
      ),
      child: AppText(
        author.isOfficial ? 'M' : _initials,
        style: AppStyle.textBold12.copyWith(
          color: author.isOfficial ? AppCustomColor.streakActive : _inks[_slot],
        ),
      ),
    );
  }
}

/// Avatar + author line, at the design's exact geometry (`S-01`/`S-04`, the same
/// on both).
///
/// The row is 22 tall — the height of the NAME, not of the avatar. The 30px
/// avatar is nudged 3 down and allowed to hang 11 BELOW the row (the design's
/// `margin:3px 0 -11px`), so the body that follows starts directly under the
/// name and the avatar reaches down into its left gutter. Letting the avatar set
/// the row height instead pushes the body a whole avatar away from the name it
/// belongs to, which is the gap this fixes.
class CommunityBylineRow extends StatelessWidget {
  const CommunityBylineRow({
    super.key,
    required this.author,
    this.createdAt,
    this.isPinned = false,
  });

  final CommunityAuthorEntity author;
  final DateTime? createdAt;
  final bool isPinned;

  /// Avatar width plus its gap. Everything below the row lines up with the NAME.
  static const double indent = 37;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22.h,
      child: Row(
        // Stretch, so the name line gets the full 22 and centres itself in it
        // while the avatar overflows past the bottom.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30.w,
            child: OverflowBox(
              maxHeight: 33.h,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 3.h),
                child: CommunityAvatar(author: author, size: 30),
              ),
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: CommunityAuthorLine(
              author: author,
              createdAt: createdAt,
              isPinned: isPinned,
            ),
          ),
        ],
      ),
    );
  }
}

/// The name line: display name, the team badge for an official post, and the
/// relative time — the design's `S-01`/`S-04` author line, identical on both.
///
/// The name and the time sit NEXT to each other rather than at opposite ends of
/// the row: the pair is one attribution, and pushing the time to the far edge
/// turns it into a second column the eye has to travel to.
class CommunityAuthorLine extends StatelessWidget {
  const CommunityAuthorLine({
    super.key,
    required this.author,
    this.createdAt,
    this.isPinned = false,
  });

  final CommunityAuthorEntity author;
  final DateTime? createdAt;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    // An empty name means the account is gone; the placeholder is localised
    // here rather than shipped by the API.
    final name = switch (author) {
      // Order matters: an anonymous post also has an empty name, and reading it
      // as a deleted account would be a different (and wrong) claim.
      _ when author.isOfficial => l10n.officialAuthorName,
      _ when author.isAnonymous => l10n.anonymousAuthorName,
      _ when author.name.isEmpty => l10n.deletedAuthorName,
      _ => author.name,
    };

    return Row(
      children: [
        Flexible(
          child: AppText(
            name,
            style: AppStyle.textBold14.copyWith(
              fontSize: 13.5.sp,
              color: AppCustomColor.communityAuthorName,
            ),
            maxLines: 1,
          ),
        ),
        if (isPinned) ...[
          SizedBox(width: 6.w),
          CommunityGlyph(
            AppAsset.svg.app.icCommunityPin,
            size: 12,
            color: AppCustomColor.streakActive,
          ),
        ],
        SizedBox(width: 6.w),
        AppText(
          // The interpunct belongs to the timestamp, not to a separator widget:
          // the design prints "· 3 giờ trước" as one quiet run of text.
          '· ${communityRelativeTime(context, createdAt)}',
          style: AppStyle.text12.copyWith(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w600,
            // This line only ever renders inside a card or the thread sheet, so
            // it takes the card ink: over glass on a photo the design's pale
            // slate washes out.
            color: studyThemeCardMuted(context, AppCustomColor.communityMuted),
          ),
        ),
      ],
    );
  }
}

/// The "MEUP" pill next to an official author's name (design `S-04`).
///
/// A badge rather than a coloured name: a purple name reads as a tappable link,
/// and this has to say "the team is answering" at a glance without competing
/// with the reply's own affordances.
class CommunityOfficialBadge extends StatelessWidget {
  const CommunityOfficialBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: AppText(
        'MEUP',
        style: AppStyle.textBold8.copyWith(
          color: AppCustomColor.streakActive,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// "3 giờ trước" / "Hôm qua", localised.
///
/// Deliberately coarse: a forum post's exact minute is noise, and the design
/// never shows one.
String communityRelativeTime(BuildContext context, DateTime? time) {
  final l10n = context.l10n.community;
  if (time == null) return '';

  final elapsed = DateTime.now().difference(time);
  if (elapsed.inMinutes < 1) return l10n.timeJustNow;
  if (elapsed.inMinutes < 60) return l10n.timeMinutes(count: elapsed.inMinutes);
  if (elapsed.inHours < 24) return l10n.timeHours(count: elapsed.inHours);
  if (elapsed.inDays == 1) return l10n.timeYesterday;
  if (elapsed.inDays < 7) return l10n.timeDays(count: elapsed.inDays);

  return l10n.timeWeeks(count: elapsed.inDays ~/ 7);
}

/// "08:24" — the wall clock on a chat line (design `S-03`).
///
/// A clock, not "3 giờ trước": a chat is read as a sequence of moments in one
/// sitting, and relative ages there make consecutive lines look further apart
/// than they are. Local time, 24h, which is what every locale the app ships
/// writes a chat timestamp in.
String communityChatClock(DateTime? time) {
  if (time == null) return '';
  final local = time.toLocal();

  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
