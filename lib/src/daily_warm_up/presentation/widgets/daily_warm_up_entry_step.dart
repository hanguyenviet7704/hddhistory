part of '../../daily_warm_up.dart';

class DailyWarmUpEntryStep extends StatefulWidget {
  const DailyWarmUpEntryStep({
    super.key,
    required this.onStart,
    required this.onMaybeLater,
  });

  final VoidCallback onStart;
  final VoidCallback onMaybeLater;

  @override
  State<DailyWarmUpEntryStep> createState() => _DailyWarmUpEntryStepState();
}

class _DailyWarmUpEntryStepState extends State<DailyWarmUpEntryStep> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _float = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || MediaQuery.accessibleNavigationOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFC7C5FA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 58.h, 20.w, 24.h),
          children: [
            AppText(
              context.l10n.dailyWarmUp.dailyChallenge,
              textAlign: TextAlign.center,
              style: AppStyle.text32.copyWith(
                color: const Color(0xFF362F82),
                fontWeight: FontWeight.w700,
              ),
            ),
            48.verticalSpace,
            SizedBox(
              height: 290.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(AppAsset.images.app.dailyWarmUpDecor.path, width: 275.w, fit: BoxFit.contain),
                  Positioned(
                    top: 85.h,
                    left: 110.w,
                    child: AnimatedBuilder(
                      animation: _float,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, reduceMotion ? 0 : _float.value),
                          child: child,
                        );
                      },
                      child: Image.asset(AppAsset.images.app.dailyWarmUpDecorOption.path, width: 145.w, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, size: 20.w, color: const Color(0xFF4B44CA)),
              8.horizontalSpace,
              Flexible(
                child: AppText(
                  context.l10n.dailyWarmUp.memoryRetentionHint,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.textBold14.copyWith(color: const Color(0xFF362F82)),
                ),
              ),
            ],
          ),
          DailyWarmUpBottomCta(
            label: context.l10n.dailyWarmUp.startWarmUp,
            enabled: true,
            width: 200.w,
            onPressed: widget.onStart,
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onMaybeLater,
            child: AppText(
              context.l10n.dailyWarmUp.maybeLater,
              style: AppStyle.text16.copyWith(
                color: const Color(0xFF362F82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }
}
