part of '../utils.dart';

class SafeBody extends StatelessWidget {
  final Widget child;
  const SafeBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      bottom: false,
      child: child,
    );
  }
}

class SafePage extends StatelessWidget {
  final Widget child;
  const SafePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      child: child,
    );
  }
}
