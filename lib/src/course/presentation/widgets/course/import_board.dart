part of '../../../course.dart';

/// Anchor for [ImportFocusGuide]'s spotlight — the guide cuts its hole around
/// whatever rect this key resolves to, so the two cannot drift apart.
final GlobalKey importBoardKey = GlobalKey();

/// "Make your own lesson" — the board under Explore's search field.
///
/// It replaces the 56px round button that used to sit BESIDE the search field
/// (design note 2026-09-04). That button had to explain itself with a focus
/// guide on first run and was still read as a second search control; the board
/// says what it does in words, and puts the two things a reader actually
/// arrives with — a YouTube link, a PDF — on the surface instead of one level
/// down inside the import screen.
class ImportBoard extends StatelessWidget {
  const ImportBoard({super.key});

  /// Design `linear-gradient(135deg,#EDECFE,#F6F1FE)`.
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDECFE), Color(0xFFF6F1FE)],
  );

  static const Color _titleInk = Color(0xFF1B1666);
  static const Color _bodyInk = Color(0xFF5B5A8C);

  void _open(BuildContext context, {bool pdf = false}) {
    AppHaptic.select();
    ExploreTracking.track(TrackingKey.exploreImportClick);
    ImportLessonRoute(pdf: pdf ? true : null).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;

    return Container(
      key: importBoardKey,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      l10n.boardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _titleInk,
                      ),
                    ),
                    3.verticalSpace,
                    AppText(
                      l10n.boardSubtitle,
                      // Two lines: the sentence wraps on a narrow phone, and
                      // AppText would otherwise silently cut it at ten.
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: _bodyInk,
                      ),
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              // The generic way in, for material that is neither of the two
              // tiles below (the import screen has its own source picker).
              Semantics(
                button: true,
                label: context.l10n.learningImport.createButton,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _open(context),
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.brandPrimary.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.add_rounded, size: 20.r, color: AppCustomColor.brandPrimary),
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _SourceTile(
                  label: l10n.sourceYoutube,
                  tint: const Color(0xFFFFE9EA),
                  glyph: _kYoutubeGlyph,
                  onTap: () => _open(context),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _SourceTile(
                  label: l10n.sourcePdf,
                  tint: const Color(0xFFE8F0FF),
                  glyph: _kPdfGlyph,
                  onTap: () => _open(context, pdf: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two source shortcuts on the board.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.label,
    required this.tint,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final Color tint;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(9.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: const Color(0x0F1B1666), blurRadius: 8.r, offset: Offset(0, 2.h)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9.r)),
                alignment: Alignment.center,
                child: SvgPicture.string(glyph, width: 19.w, height: 19.w),
              ),
              8.horizontalSpace,
              Flexible(
                child: AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand glyphs, inlined verbatim from the design so they match 1:1 without an
/// asset-bundle rebuild — the same treatment the old import button used.
const String _kYoutubeGlyph =
    '''<svg width="19" height="19" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M21 12s0-3.2-.4-4.7a2.5 2.5 0 0 0-1.8-1.8C17.3 5 12 5 12 5s-5.3 0-6.8.5a2.5 2.5 0 0 0-1.8 1.8C3 8.8 3 12 3 12s0 3.2.4 4.7a2.5 2.5 0 0 0 1.8 1.8C6.7 19 12 19 12 19s5.3 0 6.8-.5a2.5 2.5 0 0 0 1.8-1.8C21 15.2 21 12 21 12Z" fill="#FF3B41"/><path d="M10.4 9.3v5.4l4.6-2.7-4.6-2.7Z" fill="#fff"/></svg>''';

const String _kPdfGlyph =
    '''<svg width="19" height="19" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M14 3.5H7.5A2.5 2.5 0 0 0 5 6v12a2.5 2.5 0 0 0 2.5 2.5h9A2.5 2.5 0 0 0 19 18V8.5L14 3.5Z" stroke="#3567CE" stroke-width="2" stroke-linejoin="round"/><path d="M13.75 3.75V9h5" stroke="#3567CE" stroke-width="2" stroke-linejoin="round"/><path d="M8.5 13.5h7M8.5 16.5h4.5" stroke="#3567CE" stroke-width="2" stroke-linecap="round"/></svg>''';
