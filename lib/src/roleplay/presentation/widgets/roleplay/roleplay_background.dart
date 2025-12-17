part of '../../../roleplay.dart';

class RoleplayHeroBackground extends StatelessWidget {
  const RoleplayHeroBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, String>(
      selector: (state) => state.currentRoleplay.image,
      builder: (context, imageUrl) {
        if (imageUrl.isEmpty) {
          return Container(color: AppCustomColor.backgroundWhite);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CacheNetworkGraphic(
              url: imageUrl,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2F7EA6).op(0.70),
                    const Color(0xFF2F7EA6).op(0.38),
                    const Color(0xFF123D52).op(0.78),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
