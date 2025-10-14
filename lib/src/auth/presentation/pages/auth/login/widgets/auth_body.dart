part of '../../auth.dart';

class AuthBody extends StatefulWidget {
  final bool isRegister;
  const AuthBody({super.key, this.isRegister = false});

  @override
  State<AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<AuthBody> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  ValueNotifier<bool> isLogin = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      emailController.text = 'truongabc@gmail.com';
      passwordController.text = '123456';
    }
    isLogin.value = !widget.isRegister;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Stack(
        children: [
          Container(
            height: 1.sh,
            padding: EdgeInsets.symmetric(horizontal: 200.w, vertical: 140.h),
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(AppAsset.images.loginBg.path), fit: BoxFit.cover),
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: ValueListenableBuilder(
                  valueListenable: isLogin,
                  builder: (context, value, child) {
                    return AnimateSwitch(
                      child: value
                          ? LoginPanel(
                              key: const ValueKey('login'),
                              emailController: emailController,
                              passwordController: passwordController,
                              isLogin: isLogin,
                            )
                          : RegisterPanel(
                              key: const ValueKey('register'),
                              emailController: emailController,
                              passwordController: passwordController,
                              isLogin: isLogin,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Align(
          //   alignment: Alignment.topRight,
          //   child: Container(
          //     margin: EdgeInsets.fromLTRB(0, 32.h, 16.w, 0),
          //     child: LanguageBtn(enableBack: false, child: LanguageOption()),
          //   ),
          // ),
        ],
      ),
    );
  }
}
