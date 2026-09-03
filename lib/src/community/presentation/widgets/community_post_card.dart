part of '../../community.dart';

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
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
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
                  color: AppCustomColor.textPrimary,
                  height: 1.3,
                ),
                // The loudest line on the card is the last place to cut a word.
                maxLines: 100,
              ),
              SizedBox(height: 8.h),
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
                  // Whole post, not a preview of it (2026-08-25). Three lines
                  // with a "see more" under them was the previous answer and it
                  // is the wrong one for a feed people come to READ: Threads
                  // draws the entire post in the timeline, and a confession cut
                  // mid-sentence asks the reader to open a screen just to finish
                  // a paragraph. 100 is this codebase's "do not clamp" number
                  // ([AppText] asserts maxLines > 0, so there is no null).
                  if (post.body.trim().isNotEmpty)
                    AppText(
                      post.body,
                      style: AppStyle.text14.copyWith(
                        color: studyThemeCardMuted(
                          context,
                          AppCustomColor.streakTextMuted,
                        ),
                        height: 1.55,
                      ),
                      maxLines: 100,
                    ),
                  if (card != null) ...[
                    SizedBox(height: 12.h),
                    CommunityInsightCard(
                      card: card,
                      onTap: onCard == null ? null : () => onCard!(card),
                    ),
                  ],
                  if (post.attachedCourseId != null) ...[
                    SizedBox(height: 12.h),
                    CommunityAttachedCourseCard(
                      courseId: post.attachedCourseId!,
                    ),
                  ],
                  if (post.images.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    _PostImages(urls: post.images),
                  ],
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _CountAction(
                        asset: post.isLiked
                            ? AppAsset.svg.app.icCommunityHeartFill
                            : AppAsset.svg.app.icCommunityHeart,
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
                        asset: post.isSaved
                            ? AppAsset.svg.app.icCommunityBellFill
                            : AppAsset.svg.app.icCommunityBell,
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
  });

  final List<String> urls;

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

        if (widget.urls.length == 1) {
          final url = widget.urls.first;
          final natural = width / _ratioOf(url);
          return _Picture(
            url: url,
            width: width,
            height: widget.capSingle
                ? math.min(natural, width * _maxTallness)
                : natural,
            onTap: _viewerTap(0),
          );
        }

        final height =
            (width * _stripFill / _ratioOf(widget.urls.first)).clamp(
              width * _minStripHeight,
              width * _maxStripHeight,
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
    final color = isActive
        ? AppCustomColor.brandPrimary
        : studyThemeCardMuted(context, AppCustomColor.streakTextMuted);

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
