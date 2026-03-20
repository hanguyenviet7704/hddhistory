import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meup/meup.dart';

void main() {
  AppService.instance.init(() => runApp(const AppProviders(child: DMainApp())));
}

class DMainApp extends StatelessWidget {
  const DMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.common.appTitle,
      onNavigationNotification: (notification) => AppService.instance.onNavigationNotification(notification),
      routeInformationParser: AppPages.routes.routeInformationParser,
      routerDelegate: AppPages.routes.routerDelegate,
      routeInformationProvider: AppPages.routes.routeInformationProvider,
      theme: context.select((ThemeCubit theme) => theme.state.themeMaterial),
      darkTheme: AppThemeMaterial.darkTheme,
      themeMode: context.select((ThemeModeCubit themeMode) => themeMode.state.themeModeData),
      locale: context.select((LocaleCubit locale) => locale.state.localeData),
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: EasyLoading.init(),
    );
  }
}
