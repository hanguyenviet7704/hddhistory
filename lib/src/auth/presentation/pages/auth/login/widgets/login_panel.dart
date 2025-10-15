part of '../../auth.dart';

class LoginPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueNotifier<bool> isLogin;

  const LoginPanel({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLogin,
  });

  void _loginSuccess(BuildContext context) {
    final userCubit = context.read<UserCubit>();
    // Check if this is the first login for the user
    // if (userCubit.state.isFirstLogin) {
    _checkAndMarkStoryViewed(context, userCubit.state.auth.user.id);

    //   userCubit.setIsFirstLogin(false);
    // }

    context.back("loginSuccess");
  }

  void _checkAndMarkStoryViewed(BuildContext context, String userId) {}

  bool isValid(BuildContext context) {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      DMessage.showMessage(message: context.text.authPleaseFillInAllRequiredInformation, type: MessageType.error);
      return false;
    }

    if (!emailController.text.isEmailValid) {
      DMessage.showMessage(message: context.text.authInvalidEmailFormat, type: MessageType.error);
      return false;
    }

    if (passwordController.text.length < 6) {
      DMessage.showMessage(message: context.text.authPasswordMustBeAtLeastValue(amount: 6), type: MessageType.error);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          context.text.authWelcomeBackToYourJourney,
          style: AppStyle.textBold40,
          maxLines: 1,
          textAlign: TextAlign.center,
          enableFitScaleDown: true,
        ),
        20.verticalSpace,
        DTextField(
          controller: emailController,
          hint: context.text.authEmail,
          type: DTextInputType.email,
          // prefix: Padding(
          //   padding: EdgeInsets.symmetric(vertical: 16.h),
          //   child: SvgPicture.asset(AppAsset.svg.app.icMail),
          // ),
        ),
        20.verticalSpace,
        DTextField(
          controller: passwordController,
          hint: context.text.authPassword,
          type: DTextInputType.password,
          // prefix: Padding(
          //   padding: EdgeInsets.symmetric(vertical: 16.h),
          //   child: SvgPicture.asset(AppAsset.svg.app.icLockOutline),
          // ),
        ),
        if (kDebugMode) ...[
          20.verticalSpace,
          Align(
            alignment: Alignment.centerRight,
            child: AppText(
              context.text.authForgotPassword,
              onTap: () {},
              style: AppStyle.text14.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        20.verticalSpace,
        AuthButton(
          text: context.text.authSignIn,
          onPressed: () {
            if (!isValid(context)) return;

            context.read<AuthBloc>().add(
              LoginEvent(
                email: emailController.text,
                password: passwordController.text,
                onSuccess: () => _loginSuccess(context),
              ),
            );
          },
        ),
        20.verticalSpace,
        const DividerOr(),
        24.verticalSpace,
        // SocialLoginButton(
        //   text: context.text.authSignInWithService(service: 'Google'),
        //   iconPath: AppAsset.icons.logoGoogle.path,
        //   onPressed: () {
        //     context.read<AuthBloc>().add(LoginSSOGoogleEvent(onSuccess: () => _loginSuccess(context)));
        //     AppService.instance.appTrackingService.trackEvent(TrackingKey.signinSigninGoogleClick);
        //   },
        // ),
        // 16.verticalSpace,
        // if (Platform.isIOS || Platform.isMacOS) ...[
        //   SocialLoginButton(
        //     text: context.text.authSignInWithService(service: 'Apple'),
        //     iconPath: AppAsset.icons.logoApple.path,
        //     onPressed: () {
        //       context.read<AuthBloc>().add(LoginSSOAppleEvent(onSuccess: () => _loginSuccess(context)));
        //       AppService.instance.appTrackingService.trackEvent(TrackingKey.signinSigninAppleClick);
        //     },
        //   ),
        //   16.verticalSpace,
        // ],
        InkWell(
          onTap: () {
            isLogin.value = false;
            AppService.instance.appTrackingService.trackEvent(TrackingKey.signinCreateAccountClick);
          },
          child: RichText(
            text: TextSpan(
              style: AppStyle.text20.copyWith(fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: context.text.authNewMember),
                WidgetSpan(child: 10.horizontalSpace),
                TextSpan(
                  text: context.text.authCreateAnAccount,
                  style: AppStyle.textBold20.copyWith(color: AppCustomColor.orangeEC),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
