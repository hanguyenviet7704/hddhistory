part of '../intro.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme theme = context.read<ThemeCubit>().state.themeMaterial.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 30,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        title: InkWell(
          onTap: () {
            HomeRoute().go(AppConfig.instance.context!);
            AppDI.injector.get<ILocalStoreService>().setBool(key: LocalStoreKey.userPassFirstTime, value: true);
          },
          child: Align(
            alignment: Alignment.bottomRight,
            child: AppText(
              context.text.skip,
              textAlign: TextAlign.end,
              style: AppStyle.text14.copyWith(color: theme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 26),
              width: 1.sw,
              height: 0.43.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppCustomColor.gradientBackground,
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  stops: [0.22, 0.47, 0.78, 0.96],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
