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
        BlocProvider<HomeCubit>(create: (_) => AppDI.injector.get<HomeCubit>()),
        BlocProvider<ConnectivityCubit>(create: (_) => AppDI.injector.get<ConnectivityCubit>()),
        BlocProvider<DeeplinkCubit>(create: (_) => AppDI.injector.get<DeeplinkCubit>()),
        BlocProvider<UserCubit>(create: (_) => AppDI.injector.get<UserCubit>()),
        // BlocProvider<PreviewLectureCubit>(create: (_) => AppDI.injector.get<PreviewLectureCubit>()),
        BlocProvider<AuthBloc>(create: (_) => AppDI.injector.get<AuthBloc>()),
        BlocProvider<IAPCubit>(create: (_) => AppDI.injector.get<IAPCubit>()),
        BlocProvider<PaywallCubit>(create: (_) => AppDI.injector.get<PaywallCubit>()),
        BlocProvider<DeeplinkCubit>(create: (_) => AppDI.injector.get<DeeplinkCubit>()),
        BlocProvider<PageCubit>(create: (_) => AppDI.injector.get<PageCubit>()),
        BlocProvider<OnboardCubit>(create: (_) => AppDI.injector.get<OnboardCubit>()),
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
