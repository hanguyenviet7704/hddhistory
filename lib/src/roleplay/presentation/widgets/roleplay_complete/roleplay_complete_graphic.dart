part of '../../../roleplay.dart';

class RoleplayCompleteGraphic extends StatelessWidget {
  const RoleplayCompleteGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224.w,
      height: 220.h,
      child: Image.asset(
        AppAsset.images.app.hexagonDecoration.path,
        fit: BoxFit.contain,
      ),
    );
  }
}
