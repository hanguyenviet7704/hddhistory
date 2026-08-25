part of '../../community.dart';

/// What "Đăng vào Confession" carries into the composer.
///
/// A course OR a card, never both: the share sheet is opened on one thing, and
/// the composer's attachment cap is two, so pre-filling both would spend it
/// before the writer has typed a word.
@freezed
abstract class CommunityComposeSeedData with _$CommunityComposeSeedData {
  const factory CommunityComposeSeedData({
    String? courseId,
    String? courseTitle,
    CommunityAttachedCardEntity? card,

    /// Pre-selects the room. Set when `+` was tapped INSIDE a room, where the
    /// reader has already said where the post goes.
    String? roomId,
  }) = _CommunityComposeSeedData;
}

/// The hand-off between a share sheet and the composer it opens.
///
/// A one-shot holder rather than a route parameter because the payload is a
/// whole card — a title and a paragraph of text — and putting that through a
/// URL would mean encoding, length limits, and a browsable link that can
/// pre-fill someone's composer with arbitrary text.
///
/// [take] clears as it reads, so a composer opened any other way (the `+` in the
/// header) never inherits a stale attachment from a share the reader abandoned.
@lazySingleton
class CommunityComposeSeed {
  CommunityComposeSeedData? _pending;

  void set(CommunityComposeSeedData data) => _pending = data;

  CommunityComposeSeedData? take() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  void clear() => _pending = null;
}

/// Opens the composer with [seed] already attached.
///
/// Lives here rather than in the library feature so the share sheets do not
/// have to know the community's routes or its cubit — they hand over a payload
/// and this decides where it goes, including sending a guest to sign in first.
Future<void> openCommunityComposeWith(
  BuildContext context,
  CommunityComposeSeedData seed,
) async {
  final allowed = await communityRequireAccount(
    context,
    communityMemberStatus,
  );
  if (!allowed || !context.mounted) return;

  AppDI.injector.get<CommunityComposeSeed>().set(seed);

  final created = await const CommunityComposeRoute().push<bool>(context);
  if (created == true) {
    await AppDI.injector.get<CommunityFeedCubit>().refresh();
  }
}

/// The card a saved keypoint becomes when it is attached to a post.
CommunityAttachedCardEntity communityCardFromSavedCard(SavedCardEntity card) {
  return CommunityAttachedCardEntity(
    keypointId: card.keypointId,
    title: card.displayTitle,
    back: card.backText,
    courseName: card.courseTitle.text,
  );
}

/// The share sheet an attached insight card opens (design `S-08`).
///
/// Two targets only, unlike a course's five: an insight has no roadmap link to
/// copy, and the design gives it no story layouts — the card IS the story
/// image, so "More" hands that picture to whatever the reader picks.
Future<void> showCommunityInsightShareSheet(
  BuildContext context, {
  required CommunityAttachedCardEntity card,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Above the shell: the floating nav pill draws over anything below it and
    // would clip the action row (same reason as CourseShareSheet).
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x800D121C),
    builder: (_) => _CommunityInsightShareSheet(card: card),
  );
}

class _CommunityInsightShareSheet extends StatefulWidget {
  const _CommunityInsightShareSheet({required this.card});

  final CommunityAttachedCardEntity card;

  @override
  State<_CommunityInsightShareSheet> createState() =>
      _CommunityInsightShareSheetState();
}

class _CommunityInsightShareSheetState
    extends State<_CommunityInsightShareSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareToSystem() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final ok = await shareSavedQuoteCard(
      context,
      boundaryKey: _boundaryKey,
      title: widget.card.title,
    );

    if (!mounted) return;
    setState(() => _isSharing = false);
    if (!ok) {
      DMessage.showMessage(
        message: context.l10n.community.shareFailed,
        type: MessageType.error,
      );
    }
  }

  Future<void> _postToConfession() async {
    final navigator = Navigator.of(context);
    final host = context;
    final seed = CommunityComposeSeedData(card: widget.card);

    await navigator.maybePop();
    if (!host.mounted) return;

    await openCommunityComposeWith(host, seed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h + bottomInset),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppCustomColor.borderSecondary,
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                l10n.shareInsightTitle,
                style: AppStyle.textBold18.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
              ),
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).closeButtonLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppCustomColor.borderDefault,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16.r,
                      color: AppCustomColor.streakTextMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // 3:4, the design's insight-card ratio — and the boundary that gets
          // captured, so what is shared is exactly what is previewed.
          RepaintBoundary(
            key: _boundaryKey,
            child: SizedBox(
              width: 250.w,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CommunityInsightCard(card: widget.card),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShareTargetButton(
                key: const Key('insight-share-confession'),
                label: l10n.title,
                icon: Icons.people_alt_rounded,
                iconColor: AppCustomColor.textWhite,
                background: const BoxDecoration(
                  color: AppCustomColor.brandPrimary,
                  shape: BoxShape.circle,
                ),
                onTap: _postToConfession,
              ),
              ShareTargetButton(
                key: const Key('insight-share-more'),
                label: l10n.shareMore,
                icon: Icons.more_horiz_rounded,
                iconColor: AppCustomColor.textPrimary,
                background: ShareTargetButton.plainDisc,
                onTap: _shareToSystem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
