part of '../../../auth.dart';

class SetupPassPage extends StatefulWidget {
  const SetupPassPage({super.key});

  @override
  State<SetupPassPage> createState() => _SetupPassPageState();
}

class _SetupPassPageState extends State<SetupPassPage> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SubLayout(
      title: 'resetPasswordAccount',
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                'password',
                style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            10.verticalSpace,
            DTextField(
              controller: passwordController,
              hint: 'password',
              type: DTextInputType.password,
            ),
            AppText('inputConfirmPassword', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500)),
            10.verticalSpace,
            DTextField(
              controller: confirmPasswordController,
              hint: 'inputConfirmPassword',
              type: DTextInputType.password,
            ),
            10.verticalSpace,
            GradientButton(
                text: 'continueText',
                onPressed: () {
                 
                })
          ]),
        ),
      ),
    );
  }
}
