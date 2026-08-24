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

/// The name line: display name, the team badge for an official post, and the
/// relative time.
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
    final name = author.isOfficial
        ? l10n.officialAuthorName
        : (author.name.isEmpty ? l10n.deletedAuthorName : author.name);

    return Row(
      children: [
        Flexible(
          child: AppText(
            name,
            style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
            maxLines: 1,
          ),
        ),
        if (isPinned) ...[
          SizedBox(width: 6.w),
          Icon(Icons.push_pin, size: 12.sp, color: AppCustomColor.streakActive),
        ],
        SizedBox(width: 8.w),
        AppText(
          communityRelativeTime(context, createdAt),
          style: AppStyle.text12.copyWith(color: AppCustomColor.communityMuted),
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
