part of '../utils.dart';

class ScaffoldLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  ScaffoldLayout({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('LayoutScaffold'));

  final List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icHome, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icHome, width: 24.w, height: 24.w),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icMap, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icMap, width: 24.w, height: 24.w),
      label: 'Courses',
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icUser, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icUser, width: 24.w, height: 24.w),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Widget bottomNavigationBar = BlocSelector<PageCubit, PageState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) {
        return BottomNavigationBar(
          items: _items.map((e) => e).toList(),
          currentIndex: currentIndex,
          onTap: (index) => context.read<PageCubit>().handleShellRouteNavigation(index, navigationShell),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
          selectedItemColor: AppCustomColor.textPrimary,
          unselectedLabelStyle: AppStyle.textBold10.copyWith(fontWeight: FontWeight.w600),
        );
      },
    );

    if (Platform.isIOS) {
      bottomNavigationBar = SizedBox(height: 76.h, child: bottomNavigationBar);
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          bottomNavigationBar,
        ],
      ),
    );
  }
}
