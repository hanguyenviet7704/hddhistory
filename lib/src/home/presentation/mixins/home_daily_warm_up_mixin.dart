part of '../../home.dart';

mixin _HomeDailyWarmUpMixin on State<HomePage> {
  bool _dailyWarmUpCheckInFlight = false;

  Future<bool> _tryOpenDailyWarmUp() async {
    if (!mounted || _dailyWarmUpCheckInFlight) return false;
    if (_hasBlockingDailyWarmUpRoute()) return false;

    final userId = context.read<UserCubit>().state.user.id.trim();
    if (userId.isEmpty) return false;

    _dailyWarmUpCheckInFlight = true;
    final cubit = context.read<DailyWarmUpCubit>();
    late final bool canOpen;
    try {
      canOpen = await cubit.loadForHomeEntry(
        userId: userId,
        localDate: _localDateKey(DateTime.now()),
      );
    } catch (_) {
      return false;
    } finally {
      _dailyWarmUpCheckInFlight = false;
    }

    if (!mounted || !canOpen || !cubit.state.canShowEntry || _hasBlockingDailyWarmUpRoute()) {
      return false;
    }

    await DailyWarmUpRoute().push(context);
    return true;
  }

  bool _hasBlockingDailyWarmUpRoute() {
    final routeName = context.read<PageCubit>().state.currentRouteName;
    if (routeName == RouteNamed.noInternetConnection || routeName == RouteNamed.dailyWarmUp) return true;
    final surveyState = context.read<InAppSurveyCubit>().state;
    return surveyState.step != InAppSurveyStep.hidden && surveyState.step != InAppSurveyStep.entry;
  }

  String _localDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
