part of '../../in_app_survey.dart';

class InAppSurveyModalShell extends StatelessWidget {
  const InAppSurveyModalShell({
    super.key,
    required this.child,
    required this.onClose,
    this.bottom,
  });

  final Widget child;
  final VoidCallback onClose;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final maxCardWidth = min(327.w, MediaQuery.sizeOf(context).width - 48.w);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxCardWidth,
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: _surveyCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24.w,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: context.l10n.home.inAppSurveyCloseSemantics,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        AppHaptic.select();
                        onClose();
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 24.w,
                        color: const Color(0xFF7F8EA4),
                      ),
                    ),
                  ),
                ),
              ),
              12.verticalSpace,
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
              if (bottom != null) ...[
                24.verticalSpace,
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
