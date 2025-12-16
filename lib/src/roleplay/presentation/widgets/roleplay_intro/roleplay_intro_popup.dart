part of '../../../roleplay.dart';

class RoleplayIntroPopup extends StatefulWidget {
  const RoleplayIntroPopup({super.key});

  static final List<BaseMultiLanguage> _introDecorations = [
    BaseMultiLanguage(
      en: AppAsset.images.app.roleplayIntroDecor1En.path,
      vi: AppAsset.images.app.roleplayIntroDecor1Vi.path,
    ),
    BaseMultiLanguage(
      en: AppAsset.images.app.roleplayIntroDecor2En.path,
      vi: AppAsset.images.app.roleplayIntroDecor2Vi.path,
    ),
    BaseMultiLanguage(
      en: AppAsset.images.app.roleplayIntroDecor3En.path,
      vi: AppAsset.images.app.roleplayIntroDecor3Vi.path,
    ),
  ];

  static void show(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'roleplayIntroPopup',
      barrierColor: Colors.black.op(0.6),
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: RouteNamed.roleplayIntroPopup),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: const RoleplayIntroPopup(),
          ),
        );
      },
    );
  }

  @override
  State<RoleplayIntroPopup> createState() => _RoleplayIntroPopupState();
}

class _RoleplayIntroPopupState extends State<RoleplayIntroPopup> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_RoleplayIntroStep> steps = _buildSteps(context);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(steps.length),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 315.w,
                  height: 520.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppCustomColor.borderDefault,
                          blurRadius: 8.r,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: steps.length,
                              onPageChanged: (index) => setState(() => _currentPage = index),
                              itemBuilder: (context, index) => _IntroStepContent(
                                step: steps[index],
                                controller: _pageController,
                                pageCount: steps.length,
                              ),
                            ),
                          ),
                          SmoothPageIndicator(
                            controller: _pageController,
                            count: steps.length,
                            effect: ScrollingDotsEffect(
                              activeDotColor: AppCustomColor.brandPrimary,
                              dotColor: AppCustomColor.roleplayIntroDotInactive,
                              dotHeight: 8.r,
                              dotWidth: 8.r,
                              spacing: 10.w,
                            ),
                          ),
                          40.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                ),
                40.verticalSpace,
                AppText(
                  context.text.roleplay.rolePlayIntroPopupTapToContinue,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textWhite,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int total) {
    if (_currentPage < total - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }

    context.pop();
  }

  List<_RoleplayIntroStep> _buildSteps(BuildContext context) {
    final TextStyle subtitleStyle = AppStyle.text16.copyWith(
      fontWeight: FontWeight.w400,
      color: AppCustomColor.textTertiary,
      height: 24 / 16,
    );

    return [
      _RoleplayIntroStep(
        decorationPath: RoleplayIntroPopup._introDecorations[0].text,
        title: context.text.roleplay.rolePlayIntroPopupTitle1,
        subtitleSpans: [
          TextSpan(text: context.text.roleplay.rolePlayIntroPopupSubtitle1Prefix, style: subtitleStyle),
          if (context.text.roleplay.rolePlayIntroPopupSubtitle1Highlight.isNotEmpty)
            TextSpan(
              text: ' ${context.text.roleplay.rolePlayIntroPopupSubtitle1Highlight}',
              style: subtitleStyle.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
      _RoleplayIntroStep(
        decorationPath: RoleplayIntroPopup._introDecorations[1].text,
        title: context.text.roleplay.rolePlayIntroPopupTitle2,
        subtitleSpans: [
          TextSpan(text: context.text.roleplay.rolePlayIntroPopupSubtitle2, style: subtitleStyle),
        ],
      ),
      _RoleplayIntroStep(
        decorationPath: RoleplayIntroPopup._introDecorations[2].text,
        title: context.text.roleplay.rolePlayIntroPopupTitle3,
        subtitleSpans: [
          TextSpan(text: context.text.roleplay.rolePlayIntroPopupSubtitle3, style: subtitleStyle),
        ],
      ),
    ];
  }
}

class _IntroStepContent extends StatelessWidget {
  final _RoleplayIntroStep step;
  final PageController controller;
  final int pageCount;

  const _IntroStepContent({
    required this.step,
    required this.controller,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          step.decorationPath,
          height: 295.h,
          fit: BoxFit.contain,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                step.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: step.titleStyle,
              ),
              8.verticalSpace,
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppCustomColor.textTertiary,
                    height: 24 / 16,
                  ),
                  children: step.subtitleSpans,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleplayIntroStep {
  final String decorationPath;
  final String title;
  final List<InlineSpan> subtitleSpans;

  const _RoleplayIntroStep({
    required this.decorationPath,
    required this.title,
    required this.subtitleSpans,
  });

  TextStyle get titleStyle => AppStyle.text22.copyWith(
    fontWeight: FontWeight.w700,
    color: AppCustomColor.textPrimary,
    height: 1.5,
  );
}
