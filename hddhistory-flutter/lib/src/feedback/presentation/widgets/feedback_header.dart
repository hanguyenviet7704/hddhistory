part of '../../feedback.dart';

class FeedbackHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// When set, a top-right ✕ button is shown over the header (design: Exit
  /// feedback). Left null on surfaces that dismiss another way (e.g. the
  /// completed-lesson feedback), so they keep no close button.
  final VoidCallback? onClose;

  const FeedbackHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        AppText(
          title,
          textAlign: TextAlign.center,
          enableFitScaleDown: true,
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w700,
            color: AppCustomColor.textWhite,
            height: 1.5,
          ),
        ),
        if (subtitle != null) ...[
          4.verticalSpace,
          AppText(
            subtitle!,
            textAlign: TextAlign.center,
            enableFitScaleDown: true,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textWhite.op(0.7),
              height: 1.75,
            ),
          ),
        ],
      ],
    );

    if (onClose == null) return content;

    // Keep the title/subtitle centered while reserving room on both sides so a
    // long title never runs under the ✕.
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: content,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: MaterialLocalizations.of(context).closeButtonLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                onClose!.call();
              },
              child: Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppCustomColor.textWhite.op(0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 16.w, color: AppCustomColor.textWhite),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
