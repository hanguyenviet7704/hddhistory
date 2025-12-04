part of '../utils.dart';

class ScaffoldLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldLayout({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('LayoutScaffold'));

  List<BottomNavigationBarItem> _items(BuildContext context) => [
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icHome, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icHome, width: 24.w, height: 24.w),
      label: context.text.home.homeHomeButton,
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icMap, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icMap, width: 24.w, height: 24.w),
      label: context.text.home.homeCourseButton,
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(AppAsset.svg.app.icUser, width: 24.w, height: 24.w, colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary.op(.3), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(AppAsset.svg.app.icUser, width: 24.w, height: 24.w),
      label: context.text.home.homeSettingButton,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Widget bottomNavigationBar = BlocSelector<PageCubit, PageState, int>(
      selector: (state) => state.currentIndex,
      builder: (context, currentIndex) {
        return BottomNavigationBar(
          items: _items(context).map((e) => e).toList(),
          currentIndex: currentIndex,
          onTap: (index) => context.read<PageCubit>().handleShellRouteNavigation(index, navigationShell),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
          selectedItemColor: AppCustomColor.textPrimary,
          unselectedLabelStyle: AppStyle.textBold10.copyWith(fontWeight: FontWeight.w600),
          backgroundColor: Colors.transparent,
          elevation: 0,
        );
      },
    );

    return Column(
      children: [
        Expanded(child: navigationShell),
        Container(
          decoration: BoxDecoration(
            color: AppColorLight.surface,
            border: Border(
              top: BorderSide(color: AppCustomColor.borderDefault, width: 1.w),
            ),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: bottomNavigationBar,
            ),
          ),
        ),
      ],
    );
  }
}
