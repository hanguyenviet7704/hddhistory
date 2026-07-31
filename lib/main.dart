import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:meup/meup.dart';

import 'core/dev_tools/event_inspector.dart';
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
        // Floating draggable buttons for the in-app dev tools — DEV only.
        if (F.appFlavor != Flavor.dev) return app;
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            app,
            const _NetworkInspectorLauncher(),
            const _EventInspectorLauncher(),
          ],
        );
      },
    );
  }
}

/// Small draggable floating button (DEV flavor) that opens the in-memory
/// network inspector. Pushes onto the app's root navigator.
class _NetworkInspectorLauncher extends StatelessWidget {
  const _NetworkInspectorLauncher();

  @override
  Widget build(BuildContext context) {
    return const _DevToolLauncher(
      icon: Icons.wifi_tethering,
      initialOffset: Offset(12, 140),
      page: NetworkInspectorPage(),
    );
  }
}

/// Sibling of [_NetworkInspectorLauncher] for the analytics Event Inspector —
/// tap through a screen, then open this to see every event that fired.
class _EventInspectorLauncher extends StatelessWidget {
  const _EventInspectorLauncher();

  @override
  Widget build(BuildContext context) {
    return const _DevToolLauncher(
      icon: Icons.track_changes,
      initialOffset: Offset(12, 196),
      page: EventInspectorPage(),
    );
  }
}

/// Shared draggable circular launcher for the DEV-only in-app tools.
class _DevToolLauncher extends StatefulWidget {
  const _DevToolLauncher({
    required this.icon,
    required this.initialOffset,
    required this.page,
  });

  final IconData icon;

  /// Distance from the right / bottom edges.
  final Offset initialOffset;
  final Widget page;

  @override
  State<_DevToolLauncher> createState() => _DevToolLauncherState();
}

class _DevToolLauncherState extends State<_DevToolLauncher> {
  late Offset _offset = widget.initialOffset;

  void _open() {
    AppConfig.instance.rootNaviKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => widget.page),
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
          child: SizedBox(
            width: btn,
            height: btn,
            child: Icon(widget.icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
