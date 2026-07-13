part of '../../../auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _oldPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubLayout(
      title: 'changePassword',
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('password', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500)),
              DTextField(
                controller: _oldPasswordController,
                type: DTextInputType.password,
                hint: 'inputPassword',
              ),
              AppText('inputNewPassword', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500)),
              DTextField(
                hint: 'inputNewPassword',
                controller: _newPasswordController,
                type: DTextInputType.password,
              ),
              AppText('inputConfirmPassword', style: AppStyle.text12.copyWith(fontWeight: FontWeight.w500)),
              DTextField(
                hint: 'inputConfirmPassword',
                controller: _confirmPasswordController,
                type: DTextInputType.password,
              ),
              20.verticalSpace,
              GradientButton(
                text: 'changePassword',
                onPressed: () {
                 
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
