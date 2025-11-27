part of '../../roleplay.dart';

class RoleplayCompletePage extends StatelessWidget {
  const RoleplayCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 24.h, bottom: 24.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const RoleplayCompleteGraphic(),
                      16.verticalSpace,
                      RoleplayCompleteTitle(text: context.text.roleplay.rolePlayComplete),
                    ],
                  ),
                ),
              ),
              RoleplayCompleteBottomCTA(
                label: context.text.roleplay.rolePlayShowResultButton,
                onPressed: () => const RoleplayFeedbackRoute().go(context),
                bottomPadding: bottomPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
