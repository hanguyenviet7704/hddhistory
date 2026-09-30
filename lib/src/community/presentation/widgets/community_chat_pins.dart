part of '../../community.dart';

/// The violet a pin is drawn in. One constant, because the bar, the glyph, the
/// resting shadow and the jump ring are all the same colour at four opacities —
/// pulled straight from the design's `rgba(85,79,240,…)`.
const Color _pinViolet = Color(0xFFB5860F);

/// The glyph colour on a pinned bubble — the design's own `#4B44CA`, a shade
/// deeper than the bar's violet so a small 13px icon still reads against a
/// light bubble.
const Color pinInk = Color(0xFF94762A);

/// The resting look of a pinned bubble: a soft violet lift, always on.
///
/// This is what makes a pin recognisable while scrolling past it, as opposed to
/// the ring below, which is a momentary answer to a tap.
List<BoxShadow> pinnedBubbleShadow() => [
  BoxShadow(
    color: _pinViolet.withValues(alpha: 0.16),
    blurRadius: 16,
    offset: const Offset(0, 5),
  ),
];

/// The look of the message a jump just landed on — a stronger lift, for the
/// ~2s the cubit holds it.
List<BoxShadow> flashedBubbleShadow() => [
  BoxShadow(
    color: _pinViolet.withValues(alpha: 0.26),
    blurRadius: 20,
    offset: const Offset(0, 6),
  ),
];

/// The 1.6px violet ring that comes with the flash.
///
/// Drawn as a border rather than a second shadow so it stays exactly one
/// hairline at every text scale — a spread-radius ring grows with the bubble
/// and stops reading as a pointer.
Border flashedBubbleBorder() => Border.all(color: _pinViolet.withValues(alpha: 0.45), width: 1.6);

/// The strip under the header: the most recently pinned line, always visible.
///
/// Tapping the body takes the reader to the message itself; the chevron opens
/// the full list. Two targets in one row because they answer two different
/// questions — "what is this about" and "what else has been pinned" — and the
/// design gives each its own hit area rather than making one a long-press.
class CommunityChatPinBar extends StatelessWidget {
  const CommunityChatPinBar({
    super.key,
    required this.pinned,
    required this.onJump,
    required this.onOpenList,
  });

  final List<CommunityChatMessageEntity> pinned;
  final ValueChanged<CommunityChatMessageEntity> onJump;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final latest = pinned.firstOrNull;
    if (latest == null) return const SizedBox.shrink();

    final l10n = context.l10n.community;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      padding: EdgeInsets.fromLTRB(12.w, 9.h, 6.w, 9.h),
      decoration: BoxDecoration(
        color: studyThemeCardColor(context, opacity: 0.86),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: pinnedBubbleShadow(),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin_rounded, size: 15.sp, color: _pinViolet),
          SizedBox(width: 9.w),
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.chatPinBarJump,
              child: GestureDetector(
                onTap: () => onJump(latest),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      _authorName(context, latest),
                      style: AppStyle.text12.copyWith(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppCustomColor.streakTextMuted,
                        height: 1.3,
                      ),
                      maxLines: 1,
                    ),
                    SizedBox(height: 1.h),
                    // One line on purpose: the bar is a pointer, not the
                    // message. The whole text is a tap away in the sheet.
                    //
                    // Plain ink, NOT `studyThemeOnBg`. That helper is for text
                    // sitting directly ON the study background and answers
                    // near-white (#F3F4FA) over a dark one — but this text is
                    // inside a `studyThemeCardColor` card, which is WHITE. Using
                    // it here painted the line white on white and the bar looked
                    // like it had lost the message.
                    AppText(
                      latest.body,
                      style: AppStyle.text12.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppCustomColor.textPrimary,
                        height: 1.45,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.chatPinListTitle,
            child: IconButton(
              onPressed: onOpenList,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.sp,
                color: AppCustomColor.streakTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _authorName(BuildContext context, CommunityChatMessageEntity message) {
  final l10n = context.l10n.community;

  return switch (message.author) {
    _ when message.author.isOfficial => l10n.officialAuthorName,
    _ when message.author.isAnonymous => l10n.anonymousAuthorName,
    _ when message.author.name.isEmpty => l10n.deletedAuthorName,
    _ => message.author.name,
  };
}

/// Every pinned line, newest pin first. Tapping one closes the sheet and takes
/// the reader there.
Future<void> showCommunityChatPinSheet(
  BuildContext context, {
  required List<CommunityChatMessageEntity> pinned,
  required ValueChanged<CommunityChatMessageEntity> onJump,
}) {
  final l10n = context.l10n.community;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _CommunitySheetShell(
      // The count IS the heading in the design — one line, no separate title
      // repeating it underneath.
      title: l10n.chatPinCount(count: pinned.length),
      leading: Icon(Icons.push_pin_rounded, size: 17.sp, color: _pinViolet),
      onClose: () => Navigator.of(sheetContext).pop(),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 8.h),
        itemCount: pinned.length,
        separatorBuilder: (_, _) => SizedBox(height: 9.h),
        itemBuilder: (context, index) {
          final message = pinned[index];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(sheetContext).pop();
              onJump(message);
            },
            // Mỗi pin là một THẺ, không phải một dòng trôi trên nền trắng:
            // thiết kế cho nó nền #F7F7FC, bo 15, đệm 12/13. Không có nền thì
            // hai pin cạnh nhau dính thành một khối chữ và người đọc phải tự
            // dò xem dòng nào thuộc về ai.
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF7),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommunityAvatar(author: message.author, size: 30),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: AppText(
                                _authorName(context, message),
                                // Tên người viết là thứ phân biệt hai pin với
                                // nhau, nên nó đậm và tối như thiết kế — không
                                // phải chữ xám nhỏ ngang hàng với giờ.
                                style: AppStyle.textBold14.copyWith(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppCustomColor.textPrimary,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            // When it was WRITTEN, not when it was pinned: the
                            // reader is placing the line in the conversation they
                            // remember, and they remember it by the talk around it.
                            AppText(
                              communityChatClock(message.createdAt),
                              style: AppStyle.text12.copyWith(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: AppCustomColor.textMuted,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        // Three lines here, one in the bar: this list is where a
                        // reader decides which pin they want, so it has to show
                        // enough to tell them apart.
                        AppText(
                          message.body,
                          style: AppStyle.text12.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                            color: AppCustomColor.streakTextMuted,
                            height: 1.5,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// "Hướng dẫn & nội quy nhóm" (design `S-03c`).
///
/// Three blocks, not a list of paragraphs: what the room is FOR in green, what
/// gets a line taken down in red, and openers for a reader who has nothing to
/// say. That last block is the one that does work — most people who open the
/// rules were not worried about breaking them, they just did not know how to
/// start — so tapping one drops it into the composer.
Future<void> showCommunityChatGuideSheet(
  BuildContext context, {
  required CommunityChatGuideEntity guide,
  required ValueChanged<String> onUseStarter,
}) {
  final l10n = context.l10n.community;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _CommunitySheetShell(
      title: guide.title,
      subtitle: guide.intro,
      // ⓘ nằm trong một huy hiệu bo góc chứ không đứng trần: thiết kế cho nó
      // ô 34 nền #EEEDFB, và chính cái nền ấy neo tiêu đề với mô tả thành một
      // khối. Sheet ghim thì vẫn là icon trần — bản vẽ của nó cũng thế.
      leading: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7ED),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.info_outline_rounded, size: 18.sp, color: _pinViolet),
      ),
      onClose: () => Navigator.of(sheetContext).pop(),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (guide.dos.isNotEmpty)
              _GuideRuleBlock(
                label: l10n.chatGuideDo,
                items: guide.dos,
                tint: const Color(0xFFEAF7EF),
                ink: const Color(0xFF2F7D52),
                icon: Icons.check_circle_outline_rounded,
              ),
            if (guide.donts.isNotEmpty) ...[
              SizedBox(height: 10.h),
              _GuideRuleBlock(
                label: l10n.chatGuideDont,
                items: guide.donts,
                tint: const Color(0xFFFCECEC),
                ink: const Color(0xFFC0453F),
                icon: Icons.cancel_outlined,
              ),
            ],
            if (guide.starters.isNotEmpty) ...[
              SizedBox(height: 18.h),
              AppText(
                l10n.chatGuideStarters,
                style: AppStyle.textBold14.copyWith(
                  fontSize: 13.sp,
                  color: AppCustomColor.textPrimary,
                ),
                maxLines: 100,
              ),
              SizedBox(height: 8.h),
              ...guide.starters.map(
                (starter) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onUseStarter(starter);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 11.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFAF3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: AppText(
                        starter,
                        style: AppStyle.text12.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppCustomColor.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The green "Nên" / red "Không" block.
class _GuideRuleBlock extends StatelessWidget {
  const _GuideRuleBlock({
    required this.label,
    required this.items,
    required this.tint,
    required this.ink,
    required this.icon,
  });

  final String label;
  final List<String> items;
  final Color tint;
  final Color ink;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 13.h),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: ink),
              SizedBox(width: 7.w),
              AppText(
                label,
                style: AppStyle.textBold14.copyWith(
                  fontSize: 12.5.sp,
                  color: ink,
                ),
                maxLines: 1,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: AppText(
                item,
                style: AppStyle.text12.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppCustomColor.textSecondary,
                  height: 1.5,
                ),
                // House rules are read, not skimmed — nothing here may be cut.
                maxLines: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a long press on a line offers.
///
/// Pinning is NOT here: it moved to the panel, because anybody can sign into
/// that panel and there is no role behind it to tell staff from a reader. The
/// design's line saying so stays, though — a menu that silently lacks the
/// action people saw in a mock reads as broken.
/// Menu của một tin nhắn — NEO DƯỚI bong bóng, không phải sheet từ đáy.
///
/// Thiết kế (`MeUp Confession`, khối `m.menuOpen`) vẽ một thẻ trắng rộng 206
/// treo ngay dưới bong bóng, lệch trái 41 — đúng bề ngang avatar (30) cộng
/// khoảng cách (9). Bản trước dùng `showModalBottomSheet`, nên thứ hiện ra nằm
/// tận đáy màn hình: người đọc vừa chạm vào một dòng cụ thể thì câu trả lời cho
/// cú chạm đó phải ở cạnh dòng ấy, không thì họ không nối được hai việc với nhau.
///
/// [anchor] là hình chữ nhật TOÀN CỤC của cả hàng tin nhắn (avatar + bong bóng),
/// lấy ở chỗ gọi bằng `findRenderObject`. Thẻ tự lật lên trên khi dưới đáy
/// không còn chỗ — một menu bị màn hình cắt mất nửa dưới là menu không bấm được.
Future<void> showCommunityChatMessageActions(
  BuildContext context, {
  required CommunityChatMessageEntity message,
  required Rect anchor,
  required VoidCallback onReply,
  required VoidCallback onReport,
}) {
  final l10n = context.l10n.community;
  final media = MediaQuery.of(context);
  final width = 206.w;
  // Chiều cao ước lượng để quyết định lật: hai hàng + dòng khoá + viền.
  final estimated = 34.h * 2 + 46.h;
  final below = anchor.bottom + 5.h;
  final flipUp = below + estimated > media.size.height - media.padding.bottom - 12.h;
  final left = (anchor.left + 41.w).clamp(12.w, media.size.width - width - 12.w);

  return showDialog<void>(
    context: context,
    // Không phủ đen: thiết kế giữ nguyên cuộc trò chuyện sáng phía sau, menu
    // chỉ là một thẻ nhỏ. Vẫn có barrier để chạm ra ngoài là đóng.
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (sheetContext) => Stack(
      children: [
        Positioned(
          left: left,
          top: flipUp ? null : below,
          bottom: flipUp ? media.size.height - anchor.top + 5.h : null,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: const Color(0xFFEAEBF2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D121C).withValues(alpha: 0.15),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MessageAction(
                    icon: Icons.reply_rounded,
                    label: l10n.reply,
                    ink: const Color(0xFF0D121C),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onReply();
                    },
                  ),
                  _MessageAction(
                    icon: Icons.flag_outlined,
                    label: l10n.chatReportAction,
                    ink: const Color(0xFFDC3B4B),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onReport();
                    },
                  ),
                  // Ghim không phải việc của app (`community-chat.controller.ts`:
                  // "the app draws pins, it does not make them"), nên ở đây chỉ
                  // còn câu giải thích vì sao không có nút.
                  Container(
                    margin: EdgeInsets.only(top: 3.h),
                    padding: EdgeInsets.fromLTRB(9.w, 7.h, 9.w, 5.h),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F2F7))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14.sp,
                          color: const Color(0xFFB5BCC8),
                        ),
                        SizedBox(width: 9.w),
                        Expanded(
                          child: AppText(
                            l10n.chatPinAdminOnly,
                            style: AppStyle.text12.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9AA4B2),
                              height: 1.4,
                            ),
                            maxLines: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(icon, size: 15.sp, color: ink),
              SizedBox(width: 9.w),
              AppText(
                label,
                style: AppStyle.textBold14.copyWith(fontSize: 13.sp, color: ink),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rounded white card every one of these sheets sits in.
class _CommunitySheetShell extends StatelessWidget {
  const _CommunitySheetShell({
    required this.title,
    this.subtitle,
    this.leading,
    this.onClose,
    required this.child,
  });

  final String title;
  final String? subtitle;

  /// Glyph beside the heading — the pin on the pinned-messages sheet, the
  /// info disc on the house rules.
  final Widget? leading;

  /// Draws the design's ✕. Absent means the sheet is dismissed by dragging it
  /// down, which is all the shorter sheets need.
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.borderSecondary,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
            if (title.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, SizedBox(width: 11.w)],
                  // Tiêu đề VÀ mô tả cùng một cột bên phải huy hiệu.
                  //
                  // Trước đây mô tả nằm dưới cả hàng nên nó bắt đầu từ mép trái,
                  // thụt ra ngoài tiêu đề — hai dòng thuộc về nhau mà trông như
                  // hai khối rời. Thiết kế xếp chúng thành một khối, canh theo
                  // tiêu đề.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          title,
                          style: AppStyle.textBold16.copyWith(
                            fontSize: 17.sp,
                            height: 1.25,
                            color: AppCustomColor.textPrimary,
                          ),
                          maxLines: 100,
                        ),
                        if (subtitle?.isNotEmpty ?? false) ...[
                          SizedBox(height: 4.h),
                          AppText(
                            subtitle!,
                            style: AppStyle.text12.copyWith(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                              color: AppCustomColor.streakTextMuted,
                              height: 1.5,
                            ),
                            maxLines: 100,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null)
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF4F5FB),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15.sp,
                          color: AppCustomColor.streakTextMuted,
                        ),
                      ),
                    ),
                ],
              ),
            SizedBox(height: 16.h),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
