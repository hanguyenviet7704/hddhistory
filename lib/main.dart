import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:meup/meup.dart';

import 'core/dev_tools/network_inspector.dart';

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
      localizationsDelegates: quill.FlutterQuillLocalizations.localizationsDelegates,
      builder: (context, child) {
        final app = EasyLoading.init()(context, child);
        // Floating draggable button to open the network inspector — DEV only.
        if (F.appFlavor != Flavor.dev) return app;
        return Stack(
          textDirection: TextDirection.ltr,
          children: [app, const _NetworkInspectorLauncher()],
        );
      },
    );
  }
}

/// Small draggable floating button (DEV flavor) that opens the in-memory
/// network inspector. Pushes onto the app's root navigator.
class _NetworkInspectorLauncher extends StatefulWidget {
  const _NetworkInspectorLauncher();

  @override
  State<_NetworkInspectorLauncher> createState() => _NetworkInspectorLauncherState();
}

class _NetworkInspectorLauncherState extends State<_NetworkInspectorLauncher> {
  // Distance from the right / bottom edges.
  Offset _offset = const Offset(12, 140);

  void _open() {
    AppConfig.instance.rootNaviKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NetworkInspectorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double btn = 44;
    return Positioned(
      right: _offset.dx,
      bottom: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          _offset = Offset(
            (_offset.dx - d.delta.dx).clamp(0, size.width - btn),
            (_offset.dy - d.delta.dy).clamp(0, size.height - btn),
          );
        }),
        onTap: _open,
        onLongPress: _open,
        child: Material(
          color: Colors.black.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          elevation: 4,
          child: const SizedBox(
            width: btn,
            height: btn,
            child: Icon(Icons.wifi_tethering, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
