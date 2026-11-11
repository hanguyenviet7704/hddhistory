part of '../../library.dart';

/// Where a saved card can go (design `S-08`).
///
/// Sharing used to hand the picture straight to the OS, which meant the one
/// destination INSIDE the app — posting the card into Confession — did not
/// exist for a card, even though it already did for a course. This is the same
/// two-target sheet a course gets, minus the links a card has none of.
///
/// No preview: the card is on screen behind this sheet, so drawing a second
/// copy of it would only push the targets off the bottom.
Future<void> showSavedCardShareSheet(
  BuildContext context, {
  required SavedCardEntity card,
  required Future<void> Function() onShareImage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Above the shell: the floating nav pill draws over anything below it and
    // would clip the action row (same reason as CourseShareSheet).
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x800D121C),
    builder: (_) => _SavedCardShareSheet(card: card, onShareImage: onShareImage),
  );
}

class _SavedCardShareSheet extends StatelessWidget {
  const _SavedCardShareSheet({required this.card, required this.onShareImage});

  final SavedCardEntity card;
  final Future<void> Function() onShareImage;

  /// Closes this sheet FIRST: the composer is a full-screen push, and leaving
  /// the share sheet underneath means backing out of the composer lands the
  /// reader on a sheet they are done with.
  Future<void> _postToConfession(BuildContext context) async {
    final navigator = Navigator.of(context);
    final host = context;
    final seed = CommunityComposeSeedData(card: communityCardFromSavedCard(card));

    await navigator.maybePop();
    if (!host.mounted) return;

    await openCommunityComposeWith(host, seed);
  }

  Future<void> _shareImage(BuildContext context) async {
    // The capture boundary belongs to the deck behind this sheet, so the sheet
    // has to be gone before the frame is grabbed — otherwise the scrim lands in
    // the picture.
    await Navigator.of(context).maybePop();
    await onShareImage();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
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
          SizedBox(height: 18.h),
          AppText(
            card.displayTitle,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShareTargetButton(
                key: const Key('saved-card-share-confession'),
                label: context.l10n.community.title,
                icon: Icons.people_alt_rounded,
                iconColor: AppCustomColor.textWhite,
                background: const BoxDecoration(
                  color: AppCustomColor.brandPrimary,
                  shape: BoxShape.circle,
                ),
                onTap: () => _postToConfession(context),
              ),
              ShareTargetButton(
                key: const Key('saved-card-share-more'),
                label: l10n.shareMore,
                icon: Icons.more_horiz_rounded,
                iconColor: AppCustomColor.textPrimary,
                background: ShareTargetButton.plainDisc,
                onTap: () => _shareImage(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
