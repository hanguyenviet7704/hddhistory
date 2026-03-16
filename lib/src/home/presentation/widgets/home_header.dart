part of '../../home.dart';

class HomeHeaderWidget extends StatefulWidget {
  const HomeHeaderWidget({super.key});

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  bool _isOpeningStreakPopup = false;

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
              children: [
                Expanded(
                  child: BlocSelector<UserCubit, UserState, String>(
                    selector: (state) => state.user.name,
                    builder: (context, username) {
                      return AppText(
                        context.l10n.home.homeGreetingTitle(username: username),
                        enableFitScaleDown: true,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textTertiary,
                        ),
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
