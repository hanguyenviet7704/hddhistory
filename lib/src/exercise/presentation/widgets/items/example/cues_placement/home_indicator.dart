part of '../../../../../exercise.dart';

class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      alignment: Alignment.center,
      child: Container(
        width: 134,
        height: 5,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
      ),
    );
  }
}
