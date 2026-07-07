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
    HabitRoute().go(context);
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
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => _goToHabit(context, cubit),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppCustomColor.brandPrimary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AppText('🪴', style: AppStyle.text32),
                    12.horizontalSpace,
                    Expanded(
                      child: AppText(
                        context.l10n.habit.homeReminderTitle(count: state.uncheckedTodayCount),
                        style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    8.horizontalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          context.l10n.habit.homeReminderCta,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w600),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20.w, color: AppCustomColor.brandPrimary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
