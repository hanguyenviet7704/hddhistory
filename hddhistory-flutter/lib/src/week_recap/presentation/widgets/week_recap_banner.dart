part of '../../week_recap.dart';

/// The Library tab's way in to "Hành trình tuần qua".
///
/// Always present, so the feature is discoverable before the reader has ever
/// earned a recap. What changes is where it leads: with a recap ready it opens
/// the poster and wears a "MỚI" pill; without one it explains that the week is
/// still running.
class WeekRecapBanner extends StatelessWidget {
  const WeekRecapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekRecapCubit, WeekRecapState>(
      buildWhen: (previous, current) => previous.current != current.current || previous.archiveCount != current.archiveCount,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, 2.h),
          child: GestureDetector(
            onTap: () => unawaited(_onTap(context, state)),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppCustomColor.weekRecapBannerStart,
                    AppCustomColor.weekRecapBannerMid,
                    AppCustomColor.weekRecapBannerEnd,
                  ],
                  stops: [0, 0.6, 1],
                ),
              ),
              child: Stack(
                children: [
                  // Two soft discs bleeding off the top-right corner, straight
                  // from the design: they are what stops a flat gradient from
                  // reading like a placeholder block.
                  Positioned(
                    right: -18.w,
                    top: -24.h,
                    child: _disc(120.w, 0.10),
                  ),
                  Positioned(
                    right: 24.w,
                    bottom: -30.h,
                    child: _disc(70.w, 0.08),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                    child: Row(
                      children: [
                        _icon(),
                        SizedBox(width: 14.w),
                        Expanded(child: _text(context)),
                        if (state.isBannerNew) ...[
                          SizedBox(width: 10.w),
                          _pill(context),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _disc(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppCustomColor.backgroundWhite.withValues(alpha: opacity),
    ),
  );

  Widget _icon() => Container(
    width: 46.w,
    height: 46.w,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14.r),
      color: AppCustomColor.backgroundWhite.withValues(alpha: 0.18),
    ),
    child: Icon(Icons.event_available_outlined, size: 26.w, color: AppCustomColor.textWhite),
  );

  Widget _text(BuildContext context) {
    final l10n = context.l10n.weekRecap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.bannerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontWeight: FontWeight.w800,
            fontSize: 16.5.sp,
            color: AppCustomColor.textWhite,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          l10n.bannerSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontWeight: FontWeight.w500,
            fontSize: 12.5.sp,
            color: AppCustomColor.textWhite.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }

  Widget _pill(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(99.r),
      color: AppCustomColor.backgroundWhite,
    ),
    child: Text(
      context.l10n.weekRecap.bannerPillNew,
      style: TextStyle(
        fontFamily: AppFont.mulish,
        fontWeight: FontWeight.w800,
        fontSize: 11.sp,
        color: AppCustomColor.weekRecapPillInk,
      ),
    ),
  );

  /// Only the NEW banner opens the poster.
  ///
  /// Once the recap was viewed on an earlier day the banner is back in its
  /// default dress, and default taps to the "Chưa tới thứ 2" popup — the way
  /// back to an already-seen week is Sổ tay, not the banner. The design's own
  /// handler makes the same split (`tapWeekWrap`: open only while `wrapIsMonday`,
  /// else raise the lock).
  Future<void> _onTap(BuildContext context, WeekRecapState state) async {
    AppHaptic.select();
    final recap = state.current;
    if (recap != null && state.isBannerNew) {
      context.read<WeekRecapCubit>().openRecap(recap);
      await const WeekRecapRoute().push(context);

      return;
    }

    // The popup reports what the reader asked for; routing stays out here,
    // where the context is still alive and still under the providers.
    final wantsArchive = await WeekRecapLockedPopup.show(
      context,
      hasArchive: state.hasArchive,
    );
    if (wantsArchive != true || !context.mounted) return;
    await const WeekRecapArchiveRoute().push(context);
  }
}

/// The Library row into Sổ tay.
///
/// Hidden until there is at least one recap: a row that opens an empty screen
/// is a dead end, and the banner above it already carries the feature's story
/// for a reader with nothing saved yet.
class WeekRecapNotebookRow extends StatelessWidget {
  const WeekRecapNotebookRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekRecapCubit, WeekRecapState>(
      buildWhen: (previous, current) => previous.archiveCount != current.archiveCount,
      builder: (context, state) {
        if (!state.hasArchive) return const SizedBox.shrink();
        final l10n = context.l10n.weekRecap;

        return Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: GestureDetector(
            onTap: () {
              AppHaptic.select();
              const WeekRecapArchiveRoute().push(context);
            },
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                // Theme-aware like the Library rows above it: solid white here
                // read as an opaque patch over a study background while its
                // neighbours let the photo through.
                color: studyThemeCardColor(context),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppCustomColor.weekRecapRowBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 28.w, color: AppCustomColor.brandPrimary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.notebookRowTitle,
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontWeight: FontWeight.w700,
                            fontSize: 17.sp,
                            color: AppCustomColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.notebookRowCount(count: state.archiveCount),
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                            color: AppCustomColor.weekRecapRowSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20.w, color: AppCustomColor.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
