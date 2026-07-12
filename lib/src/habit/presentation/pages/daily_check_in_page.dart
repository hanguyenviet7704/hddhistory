part of '../../habit.dart';

/// Sequential daily check-in (Figma 10793:34144, design.md 5.3): one habit
/// card at a time on the lavender canvas, "Have you done this today?" ->
/// Not yet / Done, advances to the next undecided habit. Pops when all
/// active habits have been asked once.
class DailyCheckInPage extends StatefulWidget {
  const DailyCheckInPage({super.key});

  @override
  State<DailyCheckInPage> createState() => _DailyCheckInPageState();
}

class _DailyCheckInPageState extends State<DailyCheckInPage> {
  int _currentIndex = 0;
  bool _isSubmitting = false;

  List<UserHabitEntity> _pending(HabitState state) => state.activeHabits.where((h) => !h.todayDone).toList();

  Future<void> _answer(UserHabitEntity userHabit, bool done) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await context.read<HabitCubit>().checkIn(userHabit.id, done: done);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _currentIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      body: SafeBody(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            final pending = _pending(state);
            if (_currentIndex >= pending.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }

            final userHabit = pending[_currentIndex];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          context.l10n.habit.checkInTitle.toUpperCase(),
                          style: AppStyle.text12.copyWith(
                            color: AppCustomColor.brandPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(pending.length, (index) {
                          return Container(
                            margin: EdgeInsets.only(left: 4.w),
                            width: 20.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: index <= _currentIndex ? AppCustomColor.brandPrimary : AppCustomColor.brandPrimary100,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(userHabit.displayIcon, style: AppStyle.text40),
                        20.verticalSpace,
                        AppText(
                          userHabit.displayTitle,
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: AppText(
                      context.l10n.habit.checkInQuestion,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: DButton(
                          buttonType: DButtonType.fill,
                          backgroundColor: AppCustomColor.backgroundWhite,
                          onPressed: _isSubmitting ? null : () => _answer(userHabit, false),
                          customChild: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 18.w, color: AppCustomColor.errorRed),
                              8.horizontalSpace,
                              AppText(
                                context.l10n.habit.checkInNotYetButton,
                                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: DButton(
                          onPressed: _isSubmitting ? null : () => _answer(userHabit, true),
                          customChild: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 18.w, color: AppCustomColor.textWhite),
                              8.horizontalSpace,
                              AppText(
                                context.l10n.habit.checkInDoneButton,
                                style: AppStyle.text14.copyWith(color: AppCustomColor.textWhite, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: AppText(context.l10n.common.skip, style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary)),
                    ),
                  ),
                  12.verticalSpace,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
