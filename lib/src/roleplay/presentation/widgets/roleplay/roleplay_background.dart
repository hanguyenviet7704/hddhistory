part of '../../../roleplay.dart';

class RoleplayHeroBackground extends StatelessWidget {
  const RoleplayHeroBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, String>(
      selector: (state) => state.currentSection.image,
      builder: (context, imageUrl) {
        if (imageUrl.isEmpty) {
          return Container(color: AppCustomColor.backgroundWhite);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DCachedImage(
                url: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.75),
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
