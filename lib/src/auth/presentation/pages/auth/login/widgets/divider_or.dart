part of '../../auth.dart';

class DividerOr extends StatelessWidget {
  const DividerOr({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Divider(height: 1.h)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 15).w, child: AppText(context.text.authOr, style: AppStyle.text14.copyWith(color: const Color(0xFFACACAC)))),
        Expanded(child: Divider(height: 1.h)),
      ],
    );
  }
}
