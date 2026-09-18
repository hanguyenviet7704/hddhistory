part of '../../onboard_v2.dart';

/// S8 — nhắc học theo giờ. Gộp màn xin quyền thông báo cũ (p4) vào đây: user
/// chọn giờ trước, rồi "Bật thông báo" mới xin quyền OS. "Để sau" tắt tuỳ chọn
/// app và vẫn đi tiếp (reminderEnabled=false).
class OnboardV2ReminderPage extends StatefulWidget {
  const OnboardV2ReminderPage({super.key});

  @override
  State<OnboardV2ReminderPage> createState() => _OnboardV2ReminderPageState();
}

class _OnboardV2ReminderPageState extends State<OnboardV2ReminderPage> {
  bool _isHandling = false;
  Future<NotificationState>? _permissionRefreshTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _permissionRefreshTask = context.read<NotificationCubit>().refreshPermissionState(syncAuthorizedPreference: true);
      unawaited(_permissionRefreshTask);
    });
  }

  Future<void> _handlePrimary() async {
    if (_isHandling) return;
    setState(() => _isHandling = true);
    final notificationCubit = context.read<NotificationCubit>();
    var beforeState = notificationCubit.state;
    if (!beforeState.hasLoadedPermissionState) {
      beforeState = await (_permissionRefreshTask ?? notificationCubit.refreshPermissionState(syncAuthorizedPreference: true));
      if (!mounted) return;
    }
    final result = beforeState.canRequestPermission ? await notificationCubit.enableFromOnboardingGate() : beforeState;
    if (!mounted) return;
    await _complete(
      enabled: true,
      status: beforeState.canRequestPermission ? OnboardV2NotificationStatusMapper.fromRequestResult(result) : OnboardV2NotificationStatusMapper.fromCurrentState(beforeState),
    );
  }

  Future<void> _handleSecondary() async {
    if (_isHandling) return;
    setState(() => _isHandling = true);
    await context.read<NotificationCubit>().disableAppPreference();
    if (!mounted) return;
    await _complete(enabled: false, status: OnboardV2NotificationStatusMapper.maybeLater());
  }

  Future<void> _complete({required bool enabled, required OnboardV2NotificationStatus status}) async {
    context.read<UserCubit>().completeFirstTimeNotificationGate();
    final cubit = context.read<OnboardV2Cubit>();
    await cubit.submitReminder(enabled: enabled, notificationStatus: status);
    if (!mounted) return;
    if (cubit.state.currentPage == OnboardV2PageStep.p8Reminder) {
      setState(() => _isHandling = false);
    }
  }

  /// 3 khung giờ nhanh: ưu tiên config (`reminder.presets`), rỗng thì dùng bộ
  /// mặc định của design (Sáng 07:00 / Trưa 12:30 / Tối 21:00) với nhãn l10n.
  List<(String, String)> _presets(OnboardV2State state, Translations$onboarding$en onboardingL10n) {
    final fallbackLabels = [
      onbCopy(state.onboardData, 'onboardingV3P8Preset1', fallback: onboardingL10n.onboardingV3P8Preset1),
      onbCopy(state.onboardData, 'onboardingV3P8Preset2', fallback: onboardingL10n.onboardingV3P8Preset2),
      onbCopy(state.onboardData, 'onboardingV3P8Preset3', fallback: onboardingL10n.onboardingV3P8Preset3),
    ];
    const fallbackTimes = ['07:00', '12:30', '21:00'];

    if (state.reminderPresets.isEmpty) {
      return [for (var i = 0; i < 3; i++) (fallbackLabels[i], fallbackTimes[i])];
    }

    final presets = state.reminderPresets.take(3).toList();
    return [
      for (var i = 0; i < presets.length; i++)
        (
          presets[i].label.text.trim().isNotEmpty ? presets[i].label.text.trim() : fallbackLabels[i],
          presets[i].time.trim().isNotEmpty ? presets[i].time.trim() : fallbackTimes[i],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;
    final presets = _presets(state, onboardingL10n);

    return PopScope(
      canPop: false,
      child: OnboardV2ScreenShell(
        header: OnboardV2ProgressHeader(
          activeSegments: 7,
          totalSegments: _onboardV2TotalProgressSegments,
          pageStep: OnboardV2PageStep.p8Reminder,
          showBack: true,
          onBack: cubit.goBack,
        ),
        cta: OnboardV2BottomCta(
          label: onbCopy(onboardData, 'onboardingV3P8Cta', fallback: onboardingL10n.onboardingV2NotifyCta),
          isLoading: _isHandling,
          onPressed: () => unawaited(_handlePrimary()),
          secondaryLabel: onbCopy(onboardData, 'onboardingV3P8SecondaryCta', fallback: onboardingL10n.onboardingV2MaybeLaterCta),
          onSecondaryPressed: () => unawaited(_handleSecondary()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV3P8HeadingPrefix', fallback: onboardingL10n.onboardingV3P8HeadingPrefix),
              maxLines: 3,
              overflow: TextOverflow.visible,
              style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
            ),
            OnboardV2GradientText(
              onbCopy(onboardData, 'onboardingV3P8HeadingHighlight', fallback: onboardingL10n.onboardingV3P8HeadingHighlight),
              style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
            ),
            10.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV3P8Subtitle', fallback: onboardingL10n.onboardingV3P8Subtitle),
              maxLines: 3,
              overflow: TextOverflow.visible,
              style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
            ),
            20.verticalSpace,
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(color: AppCustomColor.backgroundGray, borderRadius: BorderRadius.circular(20.r)),
              child: const Center(child: OnboardV2FloatingNotificationCard()),
            ),
            20.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV3P8TimeSectionLabel', fallback: onboardingL10n.onboardingV3P8TimeSectionLabel).toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: AppStyle.text12.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w700, height: 1.6),
            ),
            12.verticalSpace,
            Center(child: OnboardV2TimeWheel(value: state.reminderTime, onChanged: cubit.setReminderTime)),
            16.verticalSpace,
            Wrap(
              spacing: 9.w,
              runSpacing: 9.h,
              children: [
                for (final preset in presets)
                  OnboardV2Chip(
                    key: ValueKey('onboard_v2_reminder_preset_${preset.$2}'),
                    label: preset.$1,
                    selected: state.reminderTime == preset.$2,
                    onTap: () => cubit.setReminderTime(preset.$2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
