part of '../../../course.dart';

class CompletedLevelAdditionalContentRequestPopup extends StatefulWidget {
  final Future<bool> Function(String requestText) onSubmit;

  const CompletedLevelAdditionalContentRequestPopup({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function(String requestText) onSubmit,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'completedLevelAdditionalContentRequestPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      useRootNavigator: false,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        return BlocProvider.value(
          value: AppDI.injector.get<ProgressCubit>(),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: CompletedLevelAdditionalContentRequestPopup(onSubmit: onSubmit),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CompletedLevelAdditionalContentRequestPopup> createState() => _CompletedLevelAdditionalContentRequestPopupState();
}

class _CompletedLevelAdditionalContentRequestPopupState extends State<CompletedLevelAdditionalContentRequestPopup> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String requestText) async {
    final success = await widget.onSubmit(requestText);
    if (!mounted || !success) return;
    context.back();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProgressCubit, ProgressState, bool>(
      selector: (state) => state.isSubmittingCompletedLevelAdditionalContentRequest,
      builder: (context, isSubmitting) {
        return Material(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 64.h),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(20.w, 64.h, 20.w, 20.h),
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundWhite,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                context.l10n.courseroadmap.additionalContentRequestPopupTitle,
                                style: AppStyle.text20.copyWith(
                                  color: AppCustomColor.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                              ),
                              24.verticalSpace,
                              _AdditionalContentRequestTextArea(controller: _controller),
                              32.verticalSpace,
                              _AdditionalContentRequestPopupActions(
                                isSubmitting: isSubmitting,
                                onLater: () => _submit(''),
                                onSend: () => _submit(_controller.text),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 20.w,
                          top: -50.h,
                          child: AppAsset.images.app.mailBox.image(
                            width: 100.w,
                            height: 100.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
