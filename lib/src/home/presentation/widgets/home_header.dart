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

  @override
  Widget build(BuildContext context) {
    final currentStreak = context.select((LearningStreakCubit cubit) => cubit.state.selectedItem.currentStreak);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            20.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: BlocSelector<ProfileCubit, ProfileState, String>(
                    selector: (state) => state.user.name,
                    builder: (context, username) {
                      final title = AppText(
                        context.l10n.home.homeGreetingTitle(username: username),
                        enableFitScaleDown: true,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textTertiary,
                        ),
                      );

                      if (!kDebugMode) return title;

                      // Debug-only manual QA hook. Remove after home widget state checks.
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _debugApplyNextHomeWidgetScenario,
                        child: title,
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
          ],
        ),
      ),
    );
  }
}
