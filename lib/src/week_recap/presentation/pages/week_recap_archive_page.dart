part of '../../week_recap.dart';

/// "Sổ tay" — every week the reader has been given, newest first.
class WeekRecapArchivePage extends StatefulWidget {
  const WeekRecapArchivePage({super.key});

  @override
  State<WeekRecapArchivePage> createState() => _WeekRecapArchivePageState();
}

class _WeekRecapArchivePageState extends State<WeekRecapArchivePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<WeekRecapCubit>().loadArchive());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: BlocBuilder<WeekRecapCubit, WeekRecapState>(
              buildWhen: (previous, current) => previous.archive != current.archive || previous.archiveStatus != current.archiveStatus,
              builder: (context, state) {
                if (state.archiveStatus == WeekRecapStatus.loading && state.archive.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.archiveStatus == WeekRecapStatus.failure && state.archive.items.isEmpty) {
                  return ErrorLayout(
                    description: context.l10n.weekRecap.loadFailed,
                    buttonText: context.l10n.weekRecap.retry,
                    onTryAgain: () => unawaited(context.read<WeekRecapCubit>().loadArchive()),
                  );
                }
                if (state.archive.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Text(
                        context.l10n.weekRecap.archiveEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          color: AppCustomColor.weekRecapPopupBody,
                        ),
                      ),
                    ),
                  );
                }

                return _grid(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      24.w,
      MediaQuery.paddingOf(context).top + 14.h,
      24.w,
      14.h,
    ),
    color: AppCustomColor.backgroundWhite,
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 26.w,
            height: 26.w,
            child: Icon(Icons.chevron_left, size: 26.w, color: AppCustomColor.textPrimary),
          ),
        ),
        Expanded(
          child: Text(
            context.l10n.weekRecap.notebookTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: AppCustomColor.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 26.w),
      ],
    ),
  );

  Widget _grid(BuildContext context, WeekRecapState state) {
    return LoadMore(
      onLoadMore: () => unawaited(context.read<WeekRecapCubit>().loadArchive(isInit: false)),
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 120.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          // 9:16 artwork plus the two lines of caption under it.
          childAspectRatio: 9 / 20,
        ),
        itemCount: state.archive.items.length,
        itemBuilder: (context, index) => _tile(context, state.archive.items[index]),
      ),
    );
  }

  /// A tile shows the artwork, not a rendered poster.
  ///
  /// Rendering twenty real posters to fill one grid would cost twenty image
  /// decodes and twenty layout passes for something the size of a thumbnail —
  /// and the week number under it is what the reader is actually scanning for.
  Widget _tile(BuildContext context, WeekRecapSummaryEntity week) {
    final l10n = context.l10n.weekRecap;

    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        WeekRecapRoute(recapId: week.id).push(context);
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppCustomColor.weekRecapTileBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: WeekRecapSlots.aspectRatio,
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
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weekLabel(number: week.weekNumber.toString().padLeft(2, '0')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppCustomColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _range(week),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: AppCustomColor.weekRecapMutedAction,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `12–18/8/2026`. The end date is `weekEnd` minus a day: the stored bound is
  /// exclusive (the next Monday), and printing it would claim a day the week
  /// does not contain.
  String _range(WeekRecapSummaryEntity week) {
    final start = week.weekStart;
    final last = week.weekEnd.subtract(const Duration(days: 1));
    final tail = '${last.day}/${last.month}/${last.year}';

    return start.month == last.month ? '${start.day}–$tail' : '${start.day}/${start.month}–$tail';
  }
}
