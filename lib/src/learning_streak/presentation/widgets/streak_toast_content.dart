part of '../../learning_streak.dart';

/// The streak popup as a top toast — the shape from `2c · Streak.dc.html`.
///
/// A toast rather than the old full-height sheet
/// ([StreakHomePopupContent]) because the new trigger fires while the user is
/// mid-task: it now appears after a couple of minutes of use, not after they
/// deliberately finished something. Taking over the screen at an arbitrary
/// moment would interrupt whatever they were reading.
class StreakToastContent extends StatelessWidget {
  const StreakToastContent({
    super.key,
    required this.streak,
    required this.onClose,
  });

  final UserLearningStreakEntity streak;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.l10n.learningStreak.toastTitle,
      child: GestureDetector(
        onTap: onClose,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.textBrand.withValues(alpha: 0.12),
                blurRadius: 38,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.l10n.learningStreak.toastTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppStyle.textBold16.copyWith(fontSize: 15.sp),
              ),
              10.verticalSpace,
              Row(
                children: [
                  Container(
                    width: 52.r,
                    height: 52.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.streakActive,
                    ),
                    child: AppText(
                      '${streak.currentStreak}',
                      maxLines: 1,
                      style: AppStyle.textBold24.copyWith(
                        fontSize: 22.sp,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(child: _ToastWeekBar(weekStudy: streak.weekStudy)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slides the toast down from above the status bar and takes it away again.
///
/// Uses an [OverlayEntry] rather than a route so it cannot swallow a back
/// press or appear in the navigator stack — it is an interruption, not a
/// destination.
class StreakToastOverlay {
  const StreakToastOverlay._();

  /// Returns false when there was no overlay to insert into, i.e. nothing was
  /// ever drawn. The caller MUST NOT spend the once-per-day token on a false —
  /// doing so burns the day on a toast the user never had a chance to see.
  static Future<bool> show(
    BuildContext context, {
    required UserLearningStreakEntity streak,
    Duration? autoHideAfter,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return false;

    final completer = Completer<void>();
    late final OverlayEntry entry;
    var removed = false;

    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 8.h,
        left: 16.w,
        right: 16.w,
        child: _StreakToastAnimator(
          child: StreakToastContent(streak: streak, onClose: remove),
        ),
      ),
    );

    overlay.insert(entry);

    if (autoHideAfter != null) {
      Future<void>.delayed(autoHideAfter, remove);
    }

    await completer.future;
    return true;
  }
}

class _StreakToastAnimator extends StatefulWidget {
  const _StreakToastAnimator({required this.child});

  final Widget child;

  @override
  State<_StreakToastAnimator> createState() => _StreakToastAnimatorState();
}

class _StreakToastAnimatorState extends State<_StreakToastAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.4),
          end: Offset.zero,
        ).animate(curve),
        child: Material(color: Colors.transparent, child: widget.child),
      ),
    );
  }
}

/// The toast's own week strip.
///
/// Not [StreakWeekBar]: the design gives the toast a smaller 28px dot and,
/// crucially, an animated flame sitting on top of today. Reusing the page
/// week-bar rendered plain rings instead, which is the difference that made
/// the toast look like the old popup rather than the new one.
class _ToastWeekBar extends StatelessWidget {
  const _ToastWeekBar({required this.weekStudy});

  final List<bool> weekStudy;

  @override
  Widget build(BuildContext context) {
    final week = weekStudy.length == 7 ? weekStudy : kLearningStreakEmptyWeekStudy;
    final todayIndex = DateTime.now().weekday - 1;
    final l10n = context.l10n.learningStreak;
    final labels = [
      l10n.weekMon,
      l10n.weekTue,
      l10n.weekWed,
      l10n.weekThu,
      l10n.weekFri,
      l10n.weekSat,
      l10n.weekSun,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isActive = week[index];
        final isToday = index == todayIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              labels[index],
              maxLines: 1,
              style: AppStyle.text12.copyWith(
                fontWeight: FontWeight.w700,
                // Navy đậm cho ngày đã học/hôm nay, xám cho ngày tương lai.
                // Design KHÔNG tô tím nhãn — tím chỉ dành cho chấm và ngọn lửa,
                // tô cả nhãn nữa thì cả dải trông rực và mất trật tự thị giác.
                color: isActive || isToday
                    ? AppCustomColor.textBrand
                    : AppCustomColor.textQuaternary,
              ),
            ),
            6.verticalSpace,
            SizedBox(
              width: 28.r,
              height: 28.r,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Hôm nay CHỈ có ngọn lửa, không có chấm phía sau: ngọn lửa
                  // hẹp hơn chấm 28px nên phần rìa tròn tím lòi ra hai bên,
                  // trông như lỗi render chứ không phải chủ đích thiết kế.
                  if (!isToday)
                    Container(
                      // Kích thước phải ĐẶT TƯỜNG MINH. Con không-Positioned
                      // của Stack nhận ràng buộc lỏng, nên Container KHÔNG con
                      // thì giãn hết 28, còn Container CÓ con (dấu tích 18sp)
                      // lại co về đúng cỡ con — thành ra chấm đã tick nhỏ hơn
                      // hẳn chấm chưa tick.
                      width: 28.r,
                      height: 28.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppCustomColor.streakActive
                            : AppCustomColor.backgroundWhite,
                        border: Border.all(
                          color: isActive
                              ? AppCustomColor.streakActive
                              : AppCustomColor.borderDefault,
                          width: 2,
                        ),
                      ),
                      // Icons.check ở 13sp quá mảnh so với nét 2.8/24 của
                      // design; check_rounded ở 18sp khớp độ dày hơn.
                      child: isActive
                          ? Icon(
                              Icons.check_rounded,
                              size: 18.sp,
                              weight: 700,
                              color: AppCustomColor.textWhite,
                            )
                          : null,
                    ),
                  // The flame overflows its 28px slot on purpose (42px in the
                  // design), so the Stack must not clip.
                  if (isToday)
                    Positioned(
                      // Phải cho offset tường minh. Positioned chỉ có
                      // width/height mà không có top/left thì KHÔNG được
                      // Stack.alignment căn giữa (alignment chỉ áp cho con
                      // không-Positioned) — nên ngọn lửa bị neo lệch góc và
                      // trông nhỏ hơn thực tế. (46-28)/2 = 9 mỗi phía.
                      left: -9.r,
                      top: -9.r,
                      width: 46.r,
                      height: 46.r,
                      child: const IgnorePointer(
                        // The design's own animated flame, exported straight
                        // from the Claude Design project. Not the orange
                        // Lottie the old popup uses — at 26px that reads as a
                        // different brand entirely.
                        child: _StreakFlame(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// The animated streak flame from `streak_flame.riv`.
///
/// rive 0.14 (rive_native) has no `RiveAnimation.asset` any more: the runtime
/// must be initialised, the file decoded, and a painter chosen by hand. The
/// painter runs the raw `'Streak'` timeline — the file's 'State Machine 1' has
/// a single state with no transitions, so driving the state machine (the new
/// API's default) shows a frozen flame.
class _StreakFlame extends StatefulWidget {
  const _StreakFlame();

  @override
  State<_StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<_StreakFlame> {
  /// One runtime init per app run, shared by every toast shown after it.
  static Future<bool>? _runtimeReady;

  rive.File? _file;
  rive.SingleAnimationPainter? _painter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _runtimeReady ??= rive.RiveNative.init().then(
      (_) => true,
      // A device the native runtime cannot start on keeps the toast working —
      // the flame is decoration, never worth an error state.
      onError: (Object _) => false,
    );
    if (!await _runtimeReady!) return;

    final file = await rive.File.asset(
      AppAsset.rive.streakFlame,
      riveFactory: rive.Factory.rive,
    );
    if (!mounted) {
      file?.dispose();
      return;
    }
    if (file == null) return;
    setState(() {
      _file = file;
      _painter = rive.SingleAnimationPainter('Streak', fit: rive.Fit.contain);
    });
  }

  @override
  void dispose() {
    _painter?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final painter = _painter;
    // Transparent while decoding (a few ms) — the toast lays out identically.
    if (file == null || painter == null) return const SizedBox.shrink();
    return rive.RiveFileWidget(file: file, painter: painter);
  }
}
