import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meup/meup.dart';

void main() {
  AppService.instance.init(() => runApp(const AppProviders(child: DMainApp())));
}

class DMainApp extends StatelessWidget {
  const DMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final easyLoadingBuilder = EasyLoading.init();

    return TranslationProvider(
      child: BlocListener<LocaleCubit, LocaleType>(
        listenWhen: (previous, current) => previous != current,
        listener: (_, locale) {
          LocaleSettings.setLocale(locale.appLocale);
        },
        child: Builder(
          builder: (context) {
            final localeState = context.select((LocaleCubit cubit) => cubit.state);
            LocaleSettings.setLocale(localeState.appLocale);
            final locale = localeState.localeData;

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => context.text.common.appTitle,
              onNavigationNotification: (notification) => AppService.instance.onNavigationNotification(notification),
              routeInformationParser: AppPages.routes.routeInformationParser,
              routerDelegate: AppPages.routes.routerDelegate,
              routeInformationProvider: AppPages.routes.routeInformationProvider,
              theme: context.select((ThemeCubit theme) => theme.state.themeMaterial),
              darkTheme: AppThemeMaterial.darkTheme,
              themeMode: context.select((ThemeModeCubit themeMode) => themeMode.state.themeModeData),
              locale: locale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => easyLoadingBuilder(context, child),
            );
          },
        ),
      ),
    );
  }
}
