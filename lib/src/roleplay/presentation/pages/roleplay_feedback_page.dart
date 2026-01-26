part of '../../roleplay.dart';

class RoleplayFeedbackPage extends StatefulWidget {
  const RoleplayFeedbackPage({super.key});

  @override
  State<RoleplayFeedbackPage> createState() => _RoleplayFeedbackPageState();
}

class _RoleplayFeedbackPageState extends State<RoleplayFeedbackPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedView = false;
  bool _hasTrackedScroll = false;
  bool _hasTrackedScrollBottom = false;
  bool _hasShownFeedbackPopup = false;

  void _trackResultView() {
    if (_hasTrackedView) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayResultScrView(trackingData);
    _hasTrackedView = true;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    final position = _scrollController.position;

    if (!_hasTrackedScroll && position.userScrollDirection != ScrollDirection.idle) {
      AppService.instance.appTrackingService.trackRoleplayResultScroll(trackingData);
      _hasTrackedScroll = true;
    }

    if (!_hasTrackedScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
      AppService.instance.appTrackingService.trackRoleplayResultScroll(trackingData);
      _hasTrackedScrollBottom = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackResultView();
      context.read<FeedbackCubit>().loadUserFeedbacks();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
      listener: (context, state) {
        if (_hasShownFeedbackPopup) return;
        if (state.userFeedback.userHasRoleplayFeedbackComplete) {
          final trackingData = RoleplayTrackingData.fromContext();
          if (trackingData == null) return;
          _hasShownFeedbackPopup = true;
          FeedbackCompleteLessonPopup.show(
            context,
            entry: FeedbackEntry.roleplay,
            courseId: trackingData.course.id,
            lessonId: trackingData.lesson.id,
            keypointId: trackingData.learningItem.keypointId,
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoleplayFeedbackChart(),
                        RoleplayFeedbackBreakdownSection(),
                        24.verticalSpace,
                        RoleplayFeedbackSummarySection(),
                      ],
                    ),
                  ),
                ),
                RoleplayFeedbackBottomCTA(
                  onPressed: () {
                    final trackingData = RoleplayTrackingData.fromContext();
                    if (trackingData != null) {
                      AppService.instance.appTrackingService.trackRoleplayResultContinue(trackingData);
                    }
                    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('nav_course');
                    CourseRoadmapRoute().go(context);
                    AppDI.injector.get<PageCubit>().setCurrentIndex(1);
                  },
                  label: context.text.roleplay.rolePlayResultStartLearningButton,
                  helperText: context.text.roleplay.rolePlayHelperTextStartLearnButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
