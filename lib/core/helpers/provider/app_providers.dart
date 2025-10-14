part of '../helpers.dart';

class AppProviders extends StatelessWidget {
  final Widget _child;
  const AppProviders({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => AppDI.injector.get<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => AppDI.injector.get<LocaleCubit>()),
        BlocProvider<ThemeModeCubit>(create: (_) => AppDI.injector.get<ThemeModeCubit>()),
        BlocProvider<HomeCubit>(create: (_) => AppDI.injector.get<HomeCubit>()),
        BlocProvider<ConnectivityCubit>(create: (_) => AppDI.injector.get<ConnectivityCubit>()),
        BlocProvider<PageCubit>(create: (_) => AppDI.injector.get<PageCubit>()),
        BlocProvider<UserCubit>(create: (_) => AppDI.injector.get<UserCubit>()),
        // BlocProvider<PreviewLectureCubit>(create: (_) => AppDI.injector.get<PreviewLectureCubit>()),
        BlocProvider<AuthBloc>(create: (_) => AppDI.injector.get<AuthBloc>()),
        BlocProvider<IAPCubit>(create: (_) => AppDI.injector.get<IAPCubit>()),
        BlocProvider<PaywallCubit>(create: (_) => AppDI.injector.get<PaywallCubit>()),
        BlocProvider<PageCubit>(create: (_) => AppDI.injector.get<PageCubit>()),
        BlocProvider<OnboardCubit>(create: (_) => AppDI.injector.get<OnboardCubit>()),
      ],
      child: ScreenUtilInit(designSize: AppGlobalValue.designSize, minTextAdapt: true, splitScreenMode: true, child: _child),
    );
  }
}
