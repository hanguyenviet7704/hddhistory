part of '../../auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      isLoading: context.select((AuthBloc bloc) => bloc.state.isLoading),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              40.verticalSpace,
              Container(padding: EdgeInsets.symmetric(vertical: 42.h), child: Image.asset(AppAsset.images.logo.path, width: 100.sp)),
              AppText('context.text.register', style: AppStyle.text22.copyWith(fontWeight: FontWeight.w600)),
              10.verticalSpace,
              Align(alignment: Alignment.centerLeft, child: AppText('context.text.phone', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500))),
              4.verticalSpace,
              DTextField(
                controller: phoneController,
                hint: 'context.text.phone',
                type: DTextInputType.phone,
                prefix: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: AppText('+84', style: AppStyle.text14.copyWith(color: Color(0xFF000000), fontWeight: FontWeight.w400)),
                      ),
                      Container(width: 1.w, height: 20.h, color: Color(0xFFACACAC)),
                    ],
                  ),
                ),
              ),
              Align(alignment: Alignment.centerLeft, child: AppText(context.text.authPassword, style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500))),
              4.verticalSpace,
              DTextField(controller: passwordController, hint: context.text.authPassword, type: DTextInputType.password),
              Align(alignment: Alignment.centerLeft, child: AppText('inputConfirmPassword', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500))),
              4.verticalSpace,
              DTextField(controller: passwordConfirmController, hint: 'inputConfirmPassword', type: DTextInputType.password),
              GradientButton(
                text: 'continueText',
                onPressed: () {
                  if (phoneController.text.isEmpty || passwordController.text.isEmpty || passwordConfirmController.text.isEmpty) {
                    _fillAllField();
                    return;
                  }

                  context.read<AuthBloc>().add(RegisterEvent(email: phoneController.text, password: passwordController.text, passwordConfirm: passwordConfirmController.text));
                },
              ),
              20.verticalSpace,
              if (kDebugMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Divider(height: 1.h)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 15).w, child: AppText(context.text.authOr, style: AppStyle.text14.copyWith(color: Color(0xFFACACAC)))),
                    Expanded(child: Divider(height: 1.h)),
                  ],
                ),
              ],
              30.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    'alreadyHaveAccount',
                    style: AppStyle.text14,
                    onTap: () {
                      // DNavigator.goNamed(RouteNamed.login);
                    },
                  ),
                  4.horizontalSpace,
                  AppText(
                    'login',
                    onTap: () {
                      // DNavigator.goNamed(RouteNamed.login);
                    },
                    style: AppStyle.text14.copyWith(color: Color(0xFFE86423), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              30.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  void _fillAllField() {
    DMessage.showMessage(message: 'pleaseFillAllFields', type: MessageType.error);
  }
}
