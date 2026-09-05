part of '../../community.dart';

/// Height of the picture band in the FEED (design `13 · Confession`:
/// `height:150px`).
///
/// Fixed rather than derived from the picture's own shape: a 9:16 screenshot
/// drawn at its natural height is a whole screen of one post, which is how a
/// feed stops being a feed. Cropping to a band costs the top and bottom of a
/// tall picture; the thread screen, one tap away, still shows it whole.
/// The tallest a feed picture may be drawn, as a multiple of the card's width.
///
/// It used to be a fixed 150-tall band for every picture, whatever its shape.
/// That made a portrait poster — the week recap is 1890×3360 — render as a
/// thin horizontal slice of itself with its own content unreadable (owner,
/// 2026-09-05: "tuỳ vào kích thước ảnh mà hiển thị chứ"). A picture now keeps
/// its own ratio and only very tall ones are capped, which is what stops one
/// screenshot from becoming a screenful.
const double _kFeedMaxTallness = 1.35;

/// One post in the feed (design `S-01`).
///
/// The whole card opens the thread; the room chip, the attachments and each
/// action button stop the tap so they do their own job instead.
///
/// The layout is title-first on purpose: the headline is what a reader scans,
/// and the author line sits UNDER it with the body indented to the avatar's
/// right edge, so a long thread reads as one block hanging off one person
/// rather than as a header with a wall beneath it.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onFollowThread,
    required this.onMenu,
    this.onTopic,
    this.onCard,
  });

  final CommunityPostEntity post;
  final VoidCallback onOpen;
  final VoidCallback onLike;

  /// The bell: "tell me when this thread gets a new comment".
  final VoidCallback onFollowThread;
  final VoidCallback onMenu;
  final void Function(CommunityPostTopicEntity topic)? onTopic;
  final void Function(CommunityAttachedCardEntity card)? onCard;

  /// Avatar width plus its gap — everything below the author line lines up
  /// with the name, not with the card edge.
  static const double _bodyIndent = CommunityBylineRow.indent;

  @override
  Widget build(BuildContext context) {
    final topic = post.topic;
    final card = post.attachedCard;
    final headline = post.subject.trim();

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        // 10 above / 9 below, down from 14/14 (design note 2026-09-04: "thu gọn
        // padding, spacing giữa các thành phần trong card bài viết"). The feed
        // shows four of these at a time and the old figure spent a third of a
        // card on air.
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 9.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppCustomColor.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic != null) ...[
              _TopicChip(topic: topic, onTap: onTopic),
              SizedBox(height: 8.h),
            ],
            // Posts written before the composer had a title field fall back to
            // leading with the body — an empty headline slot would read as a
            // rendering fault.
            if (headline.isNotEmpty) ...[
              AppText(
                headline,
                // Inside a card the ink stays dark whatever the study
                // background is — the card is opaque enough to carry it, and
                // light ink here would vanish on the stock white one.
                style: AppStyle.textBold16.copyWith(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppCustomColor.textPrimary,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
                // Two lines in the FEED. This reverses the 2026-08-25 call to
                // draw headlines whole here: with the card tightened around it,
                // an unclamped six-line headline pushed the byline, the body and
                // the actions off the visible card and the feed stopped being
                // scannable. The thread screen still shows it in full — that is
                // what opening a post is for.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // 3, not 8: the design tucks the byline up into the headline's
              // descender space (`margin-top:-6` against a 9 bottom margin).
              SizedBox(height: 3.h),
            ],
            CommunityBylineRow(
              author: post.author,
              createdAt: post.createdAt,
              isPinned: post.isPinned,
            ),
            Padding(
              padding: EdgeInsets.only(left: _bodyIndent.w, top: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Three lines in the feed, back from the unclamped body of
                  // 2026-08-25 (design note 2026-09-04: "fix hiển thị giới hạn
                  // text, ảnh ở chế độ xem nhiều bài viết"). The argument for
                  // drawing the whole post here — that a confession cut
                  // mid-sentence is a worse read — held while a card was the
                  // only thing on screen; in a four-card feed one long post
                  // buried the three under it. The thread screen still draws it
                  // whole.
                  if (post.body.trim().isNotEmpty)
                    AppText(
                      post.body,
                      style: AppStyle.text14.copyWith(
                        fontSize: 13.5.sp,
                        color: studyThemeCardMuted(
                          context,
                          AppCustomColor.streakTextMuted,
                        ),
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (card != null) ...[
                    SizedBox(height: 7.h),
                    CommunityInsightCard(
                      card: card,
                      onTap: onCard == null ? null : () => onCard!(card),
                    ),
                  ],
                  if (post.attachedCourseId != null) ...[
                    SizedBox(height: 7.h),
                    CommunityAttachedCourseCard(
                      courseId: post.attachedCourseId!,
                    ),
                  ],
                  if (post.images.isNotEmpty) ...[
                    SizedBox(height: 7.h),
                    // Each picture at its own shape, tall ones capped — see
                    // [_kFeedMaxTallness]. The thread screen draws them whole.
                    _PostImages(urls: post.images, maxTallness: _kFeedMaxTallness),
                  ],
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      _CountAction(
                        asset: post.isLiked ? AppAsset.svg.app.icCommunityHeartFill : AppAsset.svg.app.icCommunityHeart,
                        count: post.likeCount,
                        isActive: post.isLiked,
                        onTap: onLike,
                      ),
                      SizedBox(width: 20.w),
                      _CountAction(
                        asset: AppAsset.svg.app.icCommunityBubble,
                        count: post.commentCount,
                        onTap: onOpen,
                      ),
                      SizedBox(width: 20.w),
                      // The bell, not a bookmark: this subscribes the reader to
                      // the thread, and the "Đang theo dõi" tab lists exactly
                      // the posts it is lit on.
                      _CountAction(
                        asset: post.isSaved ? AppAsset.svg.app.icCommunityBellFill : AppAsset.svg.app.icCommunityBell,
                        count: post.saveCount,
                        isActive: post.isSaved,
                        onTap: onFollowThread,
                        tooltip: post.isSaved ? context.l10n.community.unfollowThread : context.l10n.community.followThread,
                      ),
                      const Spacer(),
                      _IconTap(
                        asset: AppAsset.svg.app.icCommunityMore,
                        color: studyThemeCardMuted(
                          context,
                          AppCustomColor.streakTextMuted,
                        ),
                        onTap: onMenu,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The room a post was written in, as the chip above its title.
/// Aspect ratios (width ÷ height) of post pictures already measured, by URL.
///
/// Static, and never invalidated: a feed URL points at one immutable R2 object,
/// so a card rebuilt after a scroll — or a second post carrying the same picture
/// — lays out at the right size immediately instead of guessing again.
final Map<String, double> _postImageRatios = {};

/// The post's pictures in the feed, the way Threads shows them.
///
/// **One picture** fills the card's width at its own ratio, capped at
/// [_maxTallness] so a 9:16 screenshot cannot turn one post into a screenful.
///
/// **Several** become a horizontal strip: one height, each picture as wide as
/// its own ratio makes it. Two things make it read like Threads rather than like
/// a row of thumbnails:
///
/// - the height is derived from the FIRST picture's ratio so that picture lands
///   at [_stripFill] of the available width — a tall poster therefore gets a TALL
///   strip instead of being squeezed into a fixed band, which is what made two
///   posters sit small and side by side with nothing to scroll;
/// - because the first item nearly fills the width, any second item is already
///   past the edge, so the strip always scrolls horizontally and the next
///   picture peeks in. That peek is what says "there is more here" — it replaced
///   a `+2` badge that said it in a corner while hiding the pictures themselves.
///
/// Ratios are measured from a 96px-wide decode ([_measure]), not from the
/// display-sized image: all this needs is the shape, and resolving the real
/// provider here would decode a multi-megapixel photo twice (see
/// [DCachedImage]'s `memCacheWidth` note). Server-side dimensions would remove
/// even that, and the first paint's guess with it.
class _PostImages extends StatefulWidget {
  const _PostImages({
    required this.urls,
    this.capSingle = true,
    this.tapOpensViewer = false,
    this.maxTallness,
  });

  final List<String> urls;

  /// How tall a picture may be drawn, as a multiple of the card's width.
  ///
  /// Set in the FEED (see [_kFeedMaxTallness]); null on the thread screen,
  /// where a picture is the thing you came to look at and is drawn whole.
  final double? maxTallness;

  /// Whether tapping a picture opens the full-screen viewer.
  ///
  /// True on the thread screen. False in the FEED, where the whole card is one
  /// tap target that opens the post — a tap landing on the picture there means
  /// "show me this post", not "show me this picture".
  final bool tapOpensViewer;

  /// Whether a lone picture may be cropped at [_PostImagesState._maxTallness].
  ///
  /// True in the FEED, where an endless picture makes scrolling past a post
  /// work. False on the thread screen: that page exists to look at the post, so
  /// a tall picture is drawn whole however tall it is.
  final bool capSingle;

  @override
  State<_PostImages> createState() => _PostImagesState();
}

class _PostImagesState extends State<_PostImages> {
  /// Single-picture height ceiling, as a multiple of the width available.
  /// 1.4 ≈ 5:7 — enough for the portrait posters people actually post, short of
  /// a full phone screenshot.
  static const double _maxTallness = 1.4;

  /// How much of the width the strip aims to give its first picture.
  static const double _stripFill = 0.86;

  /// Bounds on the strip's own height, as multiples of the width — a very wide
  /// first picture must not leave a letterbox, a very tall one must not run off
  /// the screen.
  static const double _minStripHeight = 0.7;
  static const double _maxStripHeight = 1.35;

  /// Per-picture ratio bounds inside the strip. Only past these does
  /// `BoxFit.cover` crop: a panorama would otherwise be several screens wide and
  /// a sliver too narrow to read.
  static const double _minItemRatio = 0.45;
  static const double _maxItemRatio = 1.6;

  /// Stand-in until a picture is measured — portrait-ish, which is what most
  /// posted pictures are.
  static const double _assumedRatio = 0.8;

  final List<VoidCallback> _cancels = [];

  @override
  void initState() {
    super.initState();
    for (final url in widget.urls) {
      _measure(url);
    }
  }

  @override
  void dispose() {
    for (final cancel in _cancels) {
      cancel();
    }
    super.dispose();
  }

  void _measure(String url) {
    if (_postImageRatios.containsKey(url)) return;

    final stream = ResizeImage(
      CachedNetworkImageProvider(url),
      width: 96,
    ).resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final ratio = info.image.width / info.image.height;
        info.dispose();
        stream.removeListener(listener);
        if (!ratio.isFinite || ratio <= 0) return;
        _postImageRatios[url] = ratio;
        // A cached picture makes this listener fire SYNCHRONOUSLY, i.e. possibly
        // inside this widget's own build — setState there throws. The ratio is
        // already in the map (so a build happening right now reads it); the
        // rebuild is only for the case where it is not.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
      onError: (_, _) => stream.removeListener(listener),
    );

    stream.addListener(listener);
    _cancels.add(() => stream.removeListener(listener));
  }

  double _ratioOf(String url) => _postImageRatios[url] ?? _assumedRatio;

  VoidCallback? _viewerTap(int index) {
    if (!widget.tapOpensViewer) return null;
    return () => unawaited(
      showCommunityImageViewer(
        context,
        urls: widget.urls,
        initialIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // The feed's cap, or the screen's own; a lone picture on the thread
        // screen has neither and is drawn whole.
        final cap = widget.maxTallness ?? _maxTallness;

        if (widget.urls.length == 1) {
          final url = widget.urls.first;
          final natural = width / _ratioOf(url);
          return _Picture(
            url: url,
            width: width,
            height: widget.capSingle ? math.min(natural, width * cap) : natural,
            onTap: _viewerTap(0),
          );
        }

        // The strip's height comes from the FIRST picture — a tall poster gets
        // a tall strip rather than a slice of itself — bounded so a row of
        // portraits cannot own the screen either.
        final height = (width * _stripFill / _ratioOf(widget.urls.first)).clamp(
          width * _minStripHeight,
          width * math.min(_maxStripHeight, cap),
        );

        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.urls.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final url = widget.urls[index];
              final ratio = _ratioOf(
                url,
              ).clamp(_minItemRatio, _maxItemRatio);
              // Never wider than the card: an item you cannot see the whole of
              // is worse than one cropped at its sides.
              return _Picture(
                url: url,
                width: math.min(height * ratio, width),
                height: height,
                onTap: _viewerTap(index),
              );
            },
          ),
        );
      },
    );
  }
}

/// One picture at an already-decided size — both axes given, so [DCachedImage]
/// decodes to fit and the shimmer stands in at exactly the right shape.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.url,
    required this.width,
    required this.height,
    this.onTap,
  });

  final String url;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // NOT `DCachedImage.enablePhotoView`: that flag drops `memCacheWidth`, which
    // would decode every thumbnail in the feed at source resolution — the exact
    // cost that field exists to avoid. The viewer is opened from here instead,
    // and asks for the full picture on its own.
    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: DCachedImage(
        url: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );

    if (onTap == null) return picture;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: picture,
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic, this.onTap});

  final CommunityPostTopicEntity topic;
  final void Function(CommunityPostTopicEntity topic)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(topic),
      // Align keeps the chip at its own width: a Container with an alignment
      // set stretches to fill the row instead.
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppCustomColor.communityChipBackground,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: AppText(
            topic.name,
            style: AppStyle.textBold10.copyWith(
              color: AppCustomColor.communityChipInk,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _CountAction extends StatelessWidget {
  const _CountAction({
    required this.asset,
    required this.count,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  /// The glyph to draw — the caller picks the filled variant for the lit state,
  /// because the design fills the heart and the bell rather than only
  /// recolouring their outline.
  final String asset;
  final int count;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Always on a card or the thread sheet, never on the background itself, so
    // the lit colour is the brand purple straight. NOT studyThemeAccentOnBg:
    // that lifts it to a pale lavender (#CFCBFF) for a dark preset, which is
    // right on a photo and nearly invisible on white — a lit heart vanished.
    final color = isActive ? AppCustomColor.brandPrimary : studyThemeCardMuted(context, AppCustomColor.streakTextMuted);

    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommunityGlyph(asset, size: 16, color: color),
          SizedBox(width: 6.w),
          AppText(
            '$count',
            // The counts are quiet in the design — medium, not bold: the glyph
            // carries the meaning and the number only qualifies it.
            style: AppStyle.text12.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );

    final label = tooltip;
    if (label == null) return button;

    // The bell is the one action whose meaning is not obvious from its shape,
    // and it is also the one the design gives no label.
    return Semantics(label: label, button: true, child: button);
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.asset, required this.onTap, this.color});

  final String asset;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: CommunityGlyph(
          asset,
          size: 17,
          color: color ?? AppCustomColor.streakTextMuted,
        ),
      ),
    );
  }
}
