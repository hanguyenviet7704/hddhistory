part of '../helpers.dart';

class AppProviders extends StatelessWidget {
  final Widget _child;
  const AppProviders({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: AppDI.injector.get<ThemeCubit>()),
        BlocProvider<LocaleCubit>.value(value: AppDI.injector.get<LocaleCubit>()),
        BlocProvider<ThemeModeCubit>.value(value: AppDI.injector.get<ThemeModeCubit>()),
        BlocProvider<HapticSettingCubit>.value(value: AppDI.injector.get<HapticSettingCubit>()),
        BlocProvider<ConnectivityCubit>(create: (_) => AppDI.injector.get<ConnectivityCubit>()),
        BlocProvider<DeeplinkCubit>(create: (_) => AppDI.injector.get<DeeplinkCubit>()),
        BlocProvider<UserCubit>.value(value: AppDI.injector.get<UserCubit>()),
        BlocProvider<PageCubit>.value(value: AppDI.injector.get<PageCubit>()),
        BlocProvider<StudyThemeCubit>.value(value: AppDI.injector.get<StudyThemeCubit>()),
      ],
      child: ScreenUtilInit(
        designSize: AppGlobalValue.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        child: TranslationProvider(child: _child),
      ),
    );
  }
}
