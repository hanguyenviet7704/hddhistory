part of '../../home.dart';

class HomeHeaderWidget extends StatefulWidget {
  const HomeHeaderWidget({super.key});

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  bool _isOpeningStreakPopup = false;
  int _debugHomeWidgetScenarioIndex = 0;

  Future<void> _openStreakPopup(int currentStreak) async {
    if (_isOpeningStreakPopup) return;

    setState(() => _isOpeningStreakPopup = true);
    AppService.instance.appTrackingService.trackHomeStreakChipClick(currentStreak: currentStreak);

    try {
      await const HomeLearningStreakRoute().push(context);
    } finally {
      if (mounted) {
        setState(() => _isOpeningStreakPopup = false);
      }
    }
  }

  Future<void> _debugApplyNextHomeWidgetScenario() async {
    if (!kDebugMode) return;

    final scenarioIndex = _debugHomeWidgetScenarioIndex;
    _debugHomeWidgetScenarioIndex = (_debugHomeWidgetScenarioIndex + 1) % 3;

    try {
      switch (scenarioIndex) {
        case 0:
          await _debugApplyHomeWidgetPayloads(
            message: 'Home widget fake: no started course',
            payloads: await _buildDebugNoStartedHomeWidgetPayloads(),
          );
          break;
        case 1:
          await _debugApplyHomeWidgetPayloads(
            message: 'Home widget fake: done all courses',
            payloads: await _buildDebugDoneAllHomeWidgetPayloads(),
          );
          break;
        default:
          await AppDI.injector.get<ClearHomeWidgetsUseCase>()(unit).run();
          await AppDI.injector
              .get<SyncHomeWidgetsUseCase>()(
                HomeWidgetSyncParams(localeCode: _debugLocaleCode()),
              )
              .run();
          _showDebugSnackBar('Home widget reset: synced from API');
      }
    } catch (error) {
      LogDev.error('Home widget debug fake failed: $error');
      _showDebugSnackBar('Home widget fake failed: $error', type: MessageType.error);
    }
  }

  Future<void> _debugApplyHomeWidgetPayloads({
    required String message,
    required List<HomeWidgetPayload> payloads,
  }) async {
    final bridge = AppDI.injector.get<HomeWidgetBridge>();

    await AppDI.injector.get<ClearHomeWidgetsUseCase>()(unit).run();
    await bridge.prepareStaticAssets();
    for (final payload in payloads) {
      await bridge.savePayload(payload);
      await bridge.updateWidget(payload.widgetType);
    }

    _showDebugSnackBar(message);
  }

  void _showDebugSnackBar(String message, {MessageType type = MessageType.success}) {
    if (!mounted) return;
    context.showDSnackBar(
      message: message,
      type: type,
      duration: const Duration(seconds: 2),
    );
  }

  String _greetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = context.select((LearningStreakCubit cubit) => cubit.state.selectedItem.currentStreak);

    return Container(
      width: double.infinity,
      color: AppCustomColor.brandPrimary,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: BlocSelector<ProfileCubit, ProfileState, String>(
                  selector: (state) => state.user.name,
                  builder: (context, username) {
                    final firstName = username.trim().split(' ').first;

                    final greetingWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${_greetingPrefix()}, $firstName',
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.backgroundWhite.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.verticalSpace,
                        AppText(
                          context.l10n.home.homeGreetingQuestion,
                          style: AppStyle.textBold20.copyWith(
                            color: AppCustomColor.backgroundWhite,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );

                    if (!kDebugMode) return greetingWidget;

                    // Debug-only manual QA hook. Remove after home widget state checks.
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _debugApplyNextHomeWidgetScenario,
                      child: greetingWidget,
                    );
                  },
                ),
              ),
              10.horizontalSpace,
              StreakHomeChip(
                currentStreak: currentStreak,
                onTap: () => _openStreakPopup(currentStreak),
              ),
            ],
          ),
          16.verticalSpace,
          // Quote card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: AppText(
                    '"',
                    style: AppStyle.text30.copyWith(
                      color: AppCustomColor.backgroundWhite.withValues(alpha: 0.4),
                      height: 1,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24.w),
                  child: AppText(
                    'Life isn\'t about finding yourself.\nLife is about creating yourself.',
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.backgroundWhite,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
