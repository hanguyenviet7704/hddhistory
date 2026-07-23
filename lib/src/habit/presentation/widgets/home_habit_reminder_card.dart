part of '../../habit.dart';

/// Home check-in reminder card (Figma `home`, PRD §9.4): a floating card that
/// overlays "Continue learning" showing how many habits are still waiting
/// today. Tapping it opens the Habit tab and hides the card for the rest of
/// the day. Renders nothing when there's nothing to check in (or already
/// dismissed today). Reads the HabitCubit singleton directly so it can be
/// dropped anywhere on Home without extra providers.
class HomeHabitReminderCard extends StatelessWidget {
  const HomeHabitReminderCard({super.key});

  void _goToHabit(BuildContext context, HabitCubit cubit) {
    cubit.dismissHomeReminderToday();
    const HabitRoute(source: 'home_banner').go(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.injector.get<HabitCubit>();
    return BlocBuilder<HabitCubit, HabitState>(
      bloc: cubit,
      builder: (context, state) {
        if (!state.showHomeReminder) return const SizedBox.shrink();
        // Figma 11634:15399: a flat brand-tinted (border/brand) card with the
        // bullseye/plant illustration bottom-aligned and overflowing the card's
        // top edge, a two-line 12px title ("N habits" in brand + "waiting..." /
        // "Keep the loop going!"), and a chevron tucked to the right.
        final count = state.uncheckedTodayCount;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () {
                AppHaptic.select();
                _goToHabit(context, cubit);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: 60.h),
                    // Left padding clears the 80px illustration parked at the
                    // bottom-left; the plant overflows above the card top.
                    padding: EdgeInsets.fromLTRB(100.w, 10.h, 12.w, 10.h),
                    decoration: BoxDecoration(
                      color: AppCustomColor.borderBrand,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: context.l10n.habit.homeReminderHabitCount(count: count),
                                      style: AppStyle.textBold12.copyWith(color: AppCustomColor.streakActive, height: 1.75),
                                    ),
                                    TextSpan(
                                      text: ' ${context.l10n.habit.homeReminderWaiting}',
                                      style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary, height: 1.75),
                                    ),
                                  ],
                                ),
                              ),
                              AppText(
                                context.l10n.habit.homeReminderSubtitle,
                                style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary, height: 1.75),
                              ),
                            ],
                          ),
                        ),
                        8.horizontalSpace,
                        Icon(Icons.chevron_right_rounded, size: 24.w, color: AppCustomColor.streakActive),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 10.w,
                    bottom: 0,
                    child: SvgPicture.asset(
                      'assets/svg/common/habit_reminder_bullseye.svg',
                      width: 80.w,
                      height: 80.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
