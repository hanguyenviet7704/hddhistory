part of '../../../onboard_v2.dart';

class OnboardV2ScreenShell extends StatelessWidget {
  const OnboardV2ScreenShell({
    super.key,
    required this.child,
    required this.cta,
    this.backgroundColor = AppCustomColor.backgroundWhite,
    this.header,
  });

  final Widget child;
  final Widget cta;
  final Color backgroundColor;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: Column(
            children: [
              ?header,
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
              cta,
            ],
          ),
        ),
      ),
    );
  }
}
