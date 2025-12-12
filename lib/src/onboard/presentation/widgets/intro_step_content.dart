part of '../../onboard.dart';

class IntroStepContent extends StatelessWidget {
  final OnboardIntroEntity intro;

  const IntroStepContent({super.key, required this.intro});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                8.verticalSpace,
                DCachedImage(
                  url: intro.image,
                  height: 260.h,
                  width: 320.w,
                  fit: BoxFit.contain,
                ),
                32.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    intro.title.text,
                    style: AppStyle.text16.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppCustomColor.textSecondary.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
                8.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    intro.content.text,
                    maxLines: 10,
                    style: AppStyle.text20.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                16.verticalSpace,
                _SourceRow(intro: intro),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final OnboardIntroEntity intro;

  const _SourceRow({required this.intro});

  @override
  Widget build(BuildContext context) {
    if (intro.sourceTitle.isEmpty && intro.source.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          'Source: ',
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w500,
            color: AppCustomColor.textTertiary,
            height: 1.75,
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () async {
              if (intro.source.isEmpty) return;
              final uri = Uri.tryParse(intro.source);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    intro.sourceTitle.isNotEmpty ? intro.sourceTitle : intro.source,
                    style: AppStyle.text14.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textTertiary,
                      decoration: TextDecoration.underline,
                      height: 1.75,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                6.horizontalSpace,
                Icon(Icons.open_in_new, size: 16.w, color: AppCustomColor.textTertiary.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
