part of '../../../auth.dart';

class LoginPage extends StatelessWidget {
  final bool isRegister;
  const LoginPage({super.key, this.isRegister = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Unfocused(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            child: Row(
              children: [
              
              ],
            ),
          ),
        ),
      ),
    );
  }
}
