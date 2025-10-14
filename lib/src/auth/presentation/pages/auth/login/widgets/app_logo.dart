part of '../../auth.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.symmetric(vertical: 42.h), child: Image.asset(AppAsset.images.logo.path, width: 100.sp));
  }
}
