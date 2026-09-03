part of '../../week_recap.dart';

/// The poster, full screen, with the share row under it.
///
/// Reached from the Library banner, the Monday popup, and a Sổ tay tile. Pushed
/// rather than switched to, so closing returns to whichever of those it was —
/// the design's own behaviour, and cheaper than tracking the origin ourselves.
class WeekRecapPage extends StatefulWidget {
  const WeekRecapPage({super.key, this.recapId});

  /// Set when opened from Sổ tay, where only the tile's summary is in memory.
  final String? recapId;

  @override
  State<WeekRecapPage> createState() => _WeekRecapPageState();
}

class _WeekRecapPageState extends State<WeekRecapPage> {
  final GlobalKey _posterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final id = widget.recapId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<WeekRecapCubit>();
      // An older week is finished and fetched by id. This week is still being
      // rebuilt server-side for three days after it closes, so ask again on the
      // way in — the poster is where the numbers are actually read, and it must
      // not be the last place to hear about them. `ensure` keeps it to one round
      // trip: a copy fetched moments ago on the Library tab is left alone.
      unawaited(id != null ? cubit.openRecapById(id) : cubit.ensureCurrentLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: BlocBuilder<WeekRecapCubit, WeekRecapState>(
        buildWhen: (previous, current) => previous.opened != current.opened || previous.openedStatus != current.openedStatus,
        builder: (context, state) {
          final recap = state.opened;

          return Column(
            children: [
              _header(context, recap),
              Expanded(
                child: switch (state.openedStatus) {
                  WeekRecapStatus.failure => ErrorLayout(
                    description: context.l10n.weekRecap.loadFailed,
                    buttonText: context.l10n.weekRecap.retry,
                    onTryAgain: () {
                      final id = widget.recapId;
                      if (id != null) unawaited(context.read<WeekRecapCubit>().openRecapById(id));
                    },
                  ),
                  _ when recap == null => const Center(child: CircularProgressIndicator()),
                  _ => _poster(recap),
                },
              ),
              if (recap != null) ...[
                WeekRecapShareBar(boundaryKey: _posterKey),
                SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, WeekRecapEntity? recap) {
    final name = AppDI.injector.get<UserCubit>().state.user.name;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.paddingOf(context).top + 12.h,
        20.w,
        12.h,
      ),
      color: AppCustomColor.backgroundWhite,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: Icon(Icons.close, size: 20.w, color: AppCustomColor.weekRecapLessonInk),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.weekRecap.posterTitle(name: name),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontWeight: FontWeight.w800,
                fontSize: 16.sp,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 28.w),
        ],
      ),
    );
  }

  /// The poster scrolls: at 9:16 it is taller than most phones once the header
  /// and the share row have taken their space, and scaling it down to fit would
  /// make the 5px course labels unreadable.
  Widget _poster(WeekRecapEntity recap) => SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: WeekRecapPoster(recap: recap, boundaryKey: _posterKey),
  );
}
