part of '../../roleplay.dart';

class RoleplayCompletePage extends StatefulWidget {
  const RoleplayCompletePage({super.key});

  @override
  State<RoleplayCompletePage> createState() => _RoleplayCompletePageState();
}

class _RoleplayCompletePageState extends State<RoleplayCompletePage> {
  bool _hasTrackedView = false;

  void _trackDoneScrView() {
    if (_hasTrackedView) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayDoneScrView(trackingData);
    _hasTrackedView = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackDoneScrView());
  }

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
                      Image.asset(
                        AppAsset.images.app.hexagonDecoration.path,
                        width: 224.w,
                        fit: BoxFit.contain,
                      ),
                      16.verticalSpace,
                      RoleplayCompleteTitle(text: context.text.roleplay.rolePlayComplete),
                    ],
                  ),
                ),
              ),
              RoleplayCompleteBottomCTA(
                label: context.text.roleplay.rolePlayShowResultButton,
                onPressed: () {
                  final trackingData = RoleplayTrackingData.fromContext();
                  if (trackingData != null) {
                    AppService.instance.appTrackingService.trackRoleplayDoneResultClick(trackingData);
                  }
                  const RoleplayFeedbackRoute().go(context);
                },
                bottomPadding: bottomPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
