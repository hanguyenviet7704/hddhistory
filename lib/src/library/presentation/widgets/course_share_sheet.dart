part of '../../library.dart';

/// Which composition a theme draws. The design's themes pick a LAYOUT as well
/// as a colour set, so the two dots are not two tints of one card.
enum CourseStoryLayout { classic, cover }

/// The story themes behind the sheet's colour dots.
///
/// Transcribed from `_Course Share.dc.html` → `THEMES`. Names are the design's
/// own ("Lavender", "Sky"); [id] is the tracking key and must never be reused
/// for a different look.
class CourseSharePalette {
  const CourseSharePalette({
    required this.id,
    required this.name,
    required this.layout,
    required this.swatch,
    required this.background,
    required this.foreground,
    required this.foregroundSoft,
    required this.chip,
    required this.buttonBackground,
    required this.buttonForeground,
    this.overlay,
  });

  final String id;
  final String name;
  final CourseStoryLayout layout;

  /// Colour of this theme's dot in the picker.
  final Color swatch;

  /// `storyBg`. A gradient even when the design gives a flat colour, so the
  /// card can paint one way for both themes.
  final Gradient background;

  /// `storyOverlay`. Null where the design says `none`.
  final Gradient? overlay;

  final Color foreground;
  final Color foregroundSoft;
  final Color chip;

  /// `storyBtnBg` — does double duty as the classic layout's headline colour
  /// and its scallop colour, which is why it is not named "button" internally.
  final Color buttonBackground;
  final Color buttonForeground;

  static const lavender = CourseSharePalette(
    id: 'violet',
    name: 'Lavender',
    layout: CourseStoryLayout.classic,
    swatch: Color(0xFFC9BEF2),
    // linear-gradient(160deg,#E6DEFB,#C9BEF2)
    background: LinearGradient(
      begin: Alignment(-0.34, -1),
      end: Alignment(0.34, 1),
      colors: [Color(0xFFE6DEFB), Color(0xFFC9BEF2)],
    ),
    // radial-gradient(120% 80% at 50% 0%, rgba(255,255,255,.5), transparent 62%)
    overlay: RadialGradient(
      center: Alignment(0, -1),
      radius: 1.2,
      colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
      stops: [0, 0.62],
    ),
    foreground: Color(0xFF4A3D7A),
    foregroundSoft: Color(0xFF7E71A8),
    chip: Color(0x99FFFFFF), // rgba(255,255,255,.6)
    buttonBackground: Color(0xFF6C63E8),
    buttonForeground: Colors.white,
  );

  static const sky = CourseSharePalette(
    id: 'cover',
    name: 'Sky',
    layout: CourseStoryLayout.cover,
    swatch: Color(0xFFF7655A),
    background: LinearGradient(colors: [Color(0xFFF7655A), Color(0xFFF7655A)]),
    foreground: Color(0xFF111111),
    foregroundSoft: Color(0x8C111111), // rgba(17,17,17,.55)
    chip: Color(0x9EFFFFFF), // rgba(255,255,255,.62)
    buttonBackground: Color(0xFFCDEF3A),
    buttonForeground: Color(0xFF2C3486),
  );

  static const all = <CourseSharePalette>[lavender, sky];
}

/// Full-height sheet that previews a course as a 9:16 story card and hands it
/// to whichever app the reader picks (design `3 · Learning` → Share course).
///
/// Replaces the text-only share the `(...)` menu used to do. The card is
/// captured from the live widget through [_boundaryKey], the same way
/// [shareSavedQuoteCard] captures a quote card — no server-side composition.
class CourseShareSheet extends StatefulWidget {
  const CourseShareSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.courseDescription,
    required this.coverUrl,
  });

  /// Needed for the roadmap link that Copy link puts on the clipboard and that
  /// rides along in the share message.
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String coverUrl;

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    required String courseTitle,
    required String courseDescription,
    required String coverUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Above the shell: this sheet is nearly full height, and the shell's
      // floating pill nav draws over anything below it — which clipped the
      // whole action row (see output_practice_intro_sheet for the precedent).
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x800D121C), // design: rgba(13,18,28,.5)
      builder: (_) => CourseShareSheet(
        courseId: courseId,
        courseTitle: courseTitle,
        courseDescription: courseDescription,
        coverUrl: coverUrl,
      ),
    );
  }

  @override
  State<CourseShareSheet> createState() => _CourseShareSheetState();
}

class _CourseShareSheetState extends State<CourseShareSheet> {
  final GlobalKey _boundaryKey = GlobalKey();

  /// Nút "Copy link" đang ở trạng thái vừa-chép.
  ///
  /// Phản hồi phải nằm NGAY TRÊN nút, không phải snackbar: sheet này là một modal
  /// route nằm trên Scaffold, còn `showDSnackBar` vẽ trong vùng Scaffold — nên
  /// snackbar hiện ra sau tấm sheet và người bấm không thấy gì. Bấm rồi không
  /// thấy gì thì người ta bấm lại, hoặc tưởng nút hỏng.
  bool _linkCopied = false;

  /// Chống đua giữa hai lần bấm liên tiếp: mỗi lần bấm cấp một token mới, và chỉ
  /// token mới nhất được phép tắt trạng thái. Không dùng Timer vì `library.dart`
  /// không import `dart:async` và đây không phải file của tôi để thêm import vào.
  int _copyToken = 0;
  CourseSharePalette _palette = CourseSharePalette.lavender;
  bool _isSharing = false;

  /// Guards every action: two taps on IG while the first capture is still
  /// encoding would hand the platform two sheets.
  Future<void> _guard(Future<void> Function() action) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// "More" — the system share sheet, image plus the fixed message.
  Future<void> _shareToSystem() => _guard(() async {
    final ok = await shareCourseStoryCard(
      context,
      boundaryKey: _boundaryKey,
      courseId: widget.courseId,
    );
    if (!ok && mounted) _failed();
  });

  /// "Copy link" — the roadmap link for THIS course, nothing else. The message
  /// belongs to a share; a clipboard paste wants just the address.
  Future<void> _copyLink() => _guard(() async {
    await Clipboard.setData(
      ClipboardData(text: courseRoadmapShareUrl(widget.courseId)),
    );
    if (!mounted) return;

    final token = ++_copyToken;
    setState(() => _linkCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || token != _copyToken) return;
    setState(() => _linkCopied = false);
  });

  /// "IG Story" / "FB Story" — hand the picture straight to that app's story
  /// composer. Falls back to the system sheet when the app isn't installed,
  /// which is the only honest thing to do with a button the reader just tapped.
  Future<void> _shareToStory(StoryPlatform platform) => _guard(() async {
    final png = await AppDI.injector.get<IMediaService>().captureWidgetWithRepaintBoundary(
      _boundaryKey,
      pixelRatio: 3,
      targetWidth: _kStoryCanvasWidth,
    );
    if (png == null) {
      if (mounted) _failed();
      return;
    }
    final handed = await AppDI.injector.get<IStoryShareService>().shareToStory(
      platform: platform,
      pngBytes: png,
    );
    if (handed || !mounted) return;
    // Not installed (or the OS refused the hand-off) — keep the tap useful.
    await _shareToSystem();
  });

  /// "Confession" — hand the course to the composer instead of to another app.
  ///
  /// Closes this sheet FIRST: the composer is a full-screen push, and leaving
  /// the share sheet underneath means backing out of the composer lands the
  /// reader on a sheet they are done with.
  Future<void> _postToConfession() async {
    final navigator = Navigator.of(context);
    final host = context;
    final seed = CommunityComposeSeedData(
      courseId: widget.courseId,
      courseTitle: widget.courseTitle,
    );

    await navigator.maybePop();
    if (!host.mounted) return;

    await openCommunityComposeWith(host, seed);
  }

  void _failed() => context.showDSnackBar(
    message: context.l10n.library.shareFailed,
    type: MessageType.error,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      // Design: the sheet stops 56px short of the ceiling rather than filling
      // it, so the course stays visible behind and the sheet reads as a layer.
      height: MediaQuery.sizeOf(context).height - 56.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h + bottomInset),
      child: Column(
        children: [
          Container(
            width: 38.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D7E0),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                l10n.shareSheetTitle,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: AppCustomColor.textPrimary,
                ),
              ),
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).closeButtonLabel,
                child: GestureDetector(
                  key: const Key('course-share-close'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6E7EE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 16.r, color: const Color(0xFF5F6F86)),
                  ),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: CourseStoryCard(
                  palette: _palette,
                  title: widget.courseTitle,
                  description: widget.courseDescription,
                  coverUrl: widget.coverUrl,
                ),
              ),
            ),
          ),
          18.verticalSpace,
          _PaletteDots(
            selected: _palette,
            onSelected: (palette) => setState(() => _palette = palette),
          ),
          20.verticalSpace,
          _ShareTargetRow(
            linkCopied: _linkCopied,
            onConfession: _postToConfession,
            onCopyLink: _copyLink,
            onInstagram: () => _shareToStory(StoryPlatform.instagram),
            onFacebook: () => _shareToStory(StoryPlatform.facebook),
            onMore: _shareToSystem,
          ),
        ],
      ),
    );
  }
}

/// Chiều rộng canvas story của cả Instagram và Facebook.
///
/// Thẻ preview trên màn hình chỉ rộng ~230pt, nên `pixelRatio: 3` một mình ra
/// ~690px và composer phải phóng lên 1080px — đó chính là chỗ ảnh bị mờ. Con số
/// này do bên NHẬN quy định, không phải do màn hình, nên nó nằm ở đây chứ không
/// suy ra từ device pixel ratio.
const double _kStoryCanvasWidth = 1080;

/// The theme dots under the preview.
class _PaletteDots extends StatelessWidget {
  const _PaletteDots({required this.selected, required this.onSelected});

  final CourseSharePalette selected;
  final ValueChanged<CourseSharePalette> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final palette in CourseSharePalette.all)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w), // design gap:12
            child: Semantics(
              button: true,
              selected: palette.id == selected.id,
              label: palette.name,
              child: GestureDetector(
                key: Key('course-share-palette-${palette.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptic.select();
                  onSelected(palette);
                },
                child: Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: palette.swatch,
                    shape: BoxShape.circle,
                    // Design: `0 0 0 2px #F4F4F8, 0 0 0 4px #554FF0` — a sheet
                    // coloured gap, then the brand ring, so the ring reads as
                    // separate from the swatch instead of outlining it.
                    boxShadow: palette.id == selected.id
                        ? const [
                            BoxShadow(color: Color(0xFFF4F4F8), spreadRadius: 2),
                            BoxShadow(color: Color(0xFF554FF0), spreadRadius: 4),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Confession · Copy link · IG Story · FB Story · More.
///
/// Disc sizes and the brand fills come from the design's own share row
/// (`_Keypoint Tap and Share` → `shareTargets`), scaled to this sheet's
/// four-up row.
class _ShareTargetRow extends StatelessWidget {
  const _ShareTargetRow({
    required this.linkCopied,
    required this.onConfession,
    required this.onCopyLink,
    required this.onInstagram,
    required this.onFacebook,
    required this.onMore,
  });

  /// Đổi icon + nhãn của ô Copy link thành xác nhận đã chép.
  final bool linkCopied;

  /// Đăng vào Confession — đích duy nhất nằm TRONG app, nên nó đứng đầu hàng.
  final VoidCallback onConfession;
  final VoidCallback onCopyLink;
  final VoidCallback onInstagram;
  final VoidCallback onFacebook;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First in the row because it is the only target that keeps the reader
        // inside MeUp — the design puts it there for the same reason.
        ShareTargetButton(
          key: const Key('course-share-confession'),
          label: context.l10n.community.title,
          icon: Icons.people_alt_rounded,
          iconColor: AppCustomColor.textWhite,
          background: const BoxDecoration(
            color: AppCustomColor.brandPrimary,
            shape: BoxShape.circle,
          ),
          onTap: onConfession,
        ),
        ShareTargetButton(
          key: const Key('course-share-copy'),
          // Nhãn NGẮN, không dùng `shareLinkCopied` ("Đã chép liên kết.") — nhãn ở
          // đây nằm dưới một icon 56 rộng cạnh ba ô khác, câu dài sẽ xuống dòng và
          // đẩy lệch cả hàng.
          label: linkCopied ? l10n.shareLinkCopiedShort : l10n.shareCopyLink,
          // Icon đổi theo, không chỉ đổi chữ: cái tick là thứ đọc được trong một
          // phần mười giây, còn chữ thì phải đọc.
          icon: linkCopied ? Icons.check_rounded : Icons.link_rounded,
          iconColor: linkCopied ? AppCustomColor.paywallPromoAppliedText : AppCustomColor.kpOptionLabel,
          background: BoxDecoration(
            color: linkCopied ? AppCustomColor.paywallPromoAppliedBg : AppCustomColor.backgroundWhite,
            shape: BoxShape.circle,
          ),
          onTap: onCopyLink,
        ),
        ShareTargetButton(
          key: const Key('course-share-instagram'),
          label: l10n.shareInstagramStory,
          icon: Icons.camera_alt_rounded,
          iconColor: AppCustomColor.textWhite,
          background: ShareTargetButton.instagramDisc,
          onTap: onInstagram,
        ),
        ShareTargetButton(
          key: const Key('course-share-facebook'),
          label: l10n.shareFacebookStory,
          icon: Icons.facebook_rounded,
          iconColor: AppCustomColor.textWhite,
          background: ShareTargetButton.facebookDisc,
          onTap: onFacebook,
        ),
        ShareTargetButton(
          key: const Key('course-share-more'),
          label: l10n.shareMore,
          icon: Icons.more_horiz_rounded,
          iconColor: AppCustomColor.kpOptionLabel,
          background: ShareTargetButton.plainDisc,
          onTap: onMore,
        ),
      ],
    );
  }
}
